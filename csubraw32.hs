-- csubraw32.hs -- Haskell float32 twin of csubraw.hs (ChatGPT review): IOUArray of unboxed Float, same forM_ kernel.
--
-- Uses only the base library so it builds with a stock ghc install.
-- Storage is a single 2D IOUArray with unboxed Floats -- contiguous
-- in memory, no per-row allocation, no boxing.  Bounds checks elided
-- with unsafeRead / unsafeWrite.
--
-- Build:  ghc -O2 csubraw32.hs

{-# LANGUAGE BangPatterns      #-}

module Main where

import           Control.Monad        (forM_, when)
import           Data.Array.Base      (unsafeRead, unsafeWrite)
import           Data.Array.IO        (IOUArray, newArray)
import           Data.IORef
import           System.Environment   (getArgs)
import           Text.Printf          (printf)

type Mat = IOUArray (Int, Int) Float

subr :: Mat -> Int -> Int -> Mat -> IO ()
subr !ina !nx !ny !out =
   forM_ [0 .. ny - 1] $ \iy -> do
      let !fiy = fromIntegral iy
      forM_ [0 .. nx - 1] $ \ix -> do
         v <- unsafeRead ina (iy * nx + ix)
         unsafeWrite out (iy * nx + ix) (v + fromIntegral ix + fiy)

main :: IO ()
main = do
   args <- getArgs
   let nrpt = case args of (a:_) -> read a; _ -> 1000 :: Int
   let nx   = case args of (_:b:_) -> read b; _ -> 2000 :: Int
   let ny   = case args of (_:_:c:_) -> read c; _ -> 10   :: Int

   ina <- newArray ((0,0), (ny-1, nx-1)) 0.0 :: IO Mat
   out <- newArray ((0,0), (ny-1, nx-1)) 0.0 :: IO Mat

   forM_ [0 .. ny - 1] $ \iy ->
      forM_ [0 .. nx - 1] $ \ix ->
         unsafeWrite ina (iy * nx + ix)
            (fromIntegral (nx - ix + ny - iy))

   printf "Arrays %d by %d count %d\n" nx ny nrpt

   forM_ [1 .. nrpt] $ \_ -> subr ina nx ny out

   -- Check
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
