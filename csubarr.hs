-- csubarr.hs -- Haskell, flat IOUArray Int Double, explicit worker loops.
-- Same storage as csubraw.hs but: the array is declared with the linear index
-- it is actually accessed by, the row base iy*nx is computed once per row
-- (GHC's native code generator does not hoist or strength-reduce the multiply
-- out of the inner loop), and the loops are hand-written tail-recursive
-- workers instead of forM_ over enumFromTo.
-- Build:  ghc -O2 csubarr.hs
{-# LANGUAGE BangPatterns #-}
module Main where

import           Control.Monad        (forM_, when)
import           Data.Array.Base      (unsafeRead, unsafeWrite)
import           Data.Array.IO        (IOUArray, newArray)
import           Data.IORef
import           System.Environment   (getArgs)
import           Text.Printf          (printf)

type Mat = IOUArray Int Double

subr :: Mat -> Int -> Int -> Mat -> IO ()
subr !ina !nx !ny !out = rows 0
  where
    rows !iy | iy >= ny  = return ()
             | otherwise = do
                  let !base = iy * nx
                      !fiy  = fromIntegral iy :: Double
                  cols base fiy 0
                  rows (iy + 1)
    cols !base !fiy !ix
      | ix >= nx  = return ()
      | otherwise = do
           let !k = base + ix
           v <- unsafeRead ina k
           unsafeWrite out k (v + fromIntegral ix + fiy)
           cols base fiy (ix + 1)
{-# NOINLINE subr #-}

main :: IO ()
main = do
   args <- getArgs
   let nrpt = case args of (a:_)     -> read a; _ -> 1000 :: Int
   let nx   = case args of (_:b:_)   -> read b; _ -> 2000 :: Int
   let ny   = case args of (_:_:c:_) -> read c; _ -> 10   :: Int

   ina <- newArray (0, nx*ny - 1) 0.0 :: IO Mat
   out <- newArray (0, nx*ny - 1) 0.0 :: IO Mat
   forM_ [0 .. ny - 1] $ \iy ->
      forM_ [0 .. nx - 1] $ \ix ->
         unsafeWrite ina (iy * nx + ix) (fromIntegral (nx - ix + ny - iy))

   printf "Arrays %d by %d count %d\n" nx ny nrpt
   forM_ [1 .. nrpt] $ \_ -> subr ina nx ny out

   errFound <- newIORef False
   forM_ [0 .. ny - 1] $ \iy ->
      forM_ [0 .. nx - 1] $ \ix -> do
         err <- readIORef errFound
         when (not err) $ do
            got  <- unsafeRead out (iy * nx + ix)
            base <- unsafeRead ina (iy * nx + ix)
            let want = base + fromIntegral ix + fromIntegral iy
            when (got /= want) $ do
               printf "Error: %f %d %d %f\n" got ix iy base
               writeIORef errFound True
