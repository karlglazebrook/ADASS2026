-- csubptr32.hs -- Haskell float32: raw Foreign pointers to Float, pointer-bump inner loop (base library only).
-- Storage is a malloc'd block of Doubles; the kernel walks it with
-- peekElemOff / pokeElemOff and a running offset, which is what the C kernel
-- does.  This is how a Haskell numerics programmer writes an FFI-grade hot
-- loop when the vector package is not available.
-- Build:  ghc -O2 csubraw-ptr.hs
{-# LANGUAGE BangPatterns #-}
module Main where

import           Control.Monad          (forM_, when)
import           Data.IORef
import           Foreign.Marshal.Array  (mallocArray)
import           Foreign.Ptr            (Ptr, plusPtr)
import           Foreign.Storable       (peek, poke, peekElemOff, pokeElemOff)
import           System.Environment     (getArgs)
import           Text.Printf            (printf)

subr :: Ptr Float -> Int -> Int -> Ptr Float -> IO ()
subr !ina !nx !ny !out = rows 0
  where
    rows !iy | iy >= ny  = return ()
             | otherwise = do
                  let !base = iy * nx
                  cols (ina `plusPtr` (4*base)) (out `plusPtr` (4*base)) (fromIntegral iy) 0
                  rows (iy + 1)
    cols :: Ptr Float -> Ptr Float -> Float -> Int -> IO ()
    cols !pi !po !fiy !ix
      | ix >= nx  = return ()
      | otherwise = do
           v <- peek pi
           poke po (v + fromIntegral ix + fiy)
           cols (pi `plusPtr` 4) (po `plusPtr` 4) fiy (ix + 1)
{-# NOINLINE subr #-}

main :: IO ()
main = do
   args <- getArgs
   let nrpt = case args of (a:_)     -> read a; _ -> 1000 :: Int
   let nx   = case args of (_:b:_)   -> read b; _ -> 2000 :: Int
   let ny   = case args of (_:_:c:_) -> read c; _ -> 10   :: Int

   ina <- mallocArray (nx*ny) :: IO (Ptr Float)
   out <- mallocArray (nx*ny) :: IO (Ptr Float)
   forM_ [0 .. nx*ny - 1] $ \k -> pokeElemOff out k 0.0
   forM_ [0 .. ny - 1] $ \iy ->
      forM_ [0 .. nx - 1] $ \ix ->
         pokeElemOff ina (iy * nx + ix) (fromIntegral (nx - ix + ny - iy))

   printf "Arrays %d by %d count %d\n" nx ny nrpt
   forM_ [1 .. nrpt] $ \_ -> subr ina nx ny out

   errFound <- newIORef False
   forM_ [0 .. ny - 1] $ \iy ->
      forM_ [0 .. nx - 1] $ \ix -> do
         err <- readIORef errFound
         when (not err) $ do
            got  <- peekElemOff out (iy * nx + ix)
            base <- peekElemOff ina (iy * nx + ix)
            let want = base + fromIntegral ix + fromIntegral iy
            when (got /= want) $ do
               printf "Error: %f %d %d %f\n" got ix iy base
               writeIORef errFound True
