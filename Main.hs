{-# LANGUAGE FlexibleContexts #-}

module Main where

import Control.Monad.Fix      (MonadFix)

import Reflex
import Graphics.Gloss (Picture, Display(..), white)

import Buttons
import GlossInterface

-- Utilities

ifB :: (Reflex t) => Behavior t Bool -> Behavior t a -> Behavior t a -> Behavior t a
ifB prd b1 b2 = pull $ do
  p <- sample prd
  if p then sample b1 else sample b2

filterEq :: (Eq a, Reflex t) => a -> Int -> Event t a -> Event t Int
filterEq x n = (n <$) . ffilter (== x)

-- FRP network

mainReflex ::(Reflex t, MonadHold t m, MonadFix m)
           => Event t Float
           -> Event t InputEvent
           -> m (Behavior t Picture)
mainReflex _ glossEvent = do
    -- Part 1: static version

    -- Input

    let click0  = filterEq (Just Click) 1 $ filter0  <$> glossEvent
        click5  = filterEq (Just Click) 1 $ filter5  <$> glossEvent
        click10 = filterEq (Just Click) 1 $ filter10 <$> glossEvent

        toggle0  = filterEq (Just Toggle) 0 $ filter0  <$> glossEvent
        toggle5  = filterEq (Just Toggle) 0 $ filter5  <$> glossEvent
        toggle10 = filterEq (Just Toggle) 0 $ filter10 <$> glossEvent

    -- Behaviour

    mode0  <- current <$> toggle True toggle0
    mode5  <- current <$> toggle True toggle5
    mode10 <- current <$> toggle True toggle10

    count0  <- current <$> foldDyn (\a b -> a * (b+a)) 0 (leftmost [toggle0, click0])
    count5  <- current <$> count (gate mode5 click5)
    count10 <- current <$> count click10

    -- Part 1: static version

    -- Scenario 0: generate new graphs and switch to the latest one.


    -- Output

    let minus1   = constant (-1)
        output0  = ifB mode0 count0 minus1
        output5  = ifB mode5 count5 minus1
        output10 = ifB mode10 count10 minus1

        picture = pull $  renderButtons
                      <$> sample output0  <*> pure Nothing
                      <*> sample output5  <*> pure Nothing
                      <*> sample output10 <*> pure Nothing
    return picture

-- Gloss event loop

main :: IO ()
main = playReflex (InWindow "Reflex Example" (320, 240) (800, 200))
                  white
                  30
                  mainReflex
