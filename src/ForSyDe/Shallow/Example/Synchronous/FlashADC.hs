-----------------------------------------------------------------------------
-- |
-- Module      :  FlashADC
-- Copyright   :  José Edil Guimarães de Medeiros
-- License     :  BSD-style (see the file LICENSE)
-- 
-- Maintainer  :  j.edil@ene.unb.br
-- Stability   :  experimental
-- Portability :  portable
--
-- The first order RC circuit is described by the differential
-- equation dVo/dt + Vo/(RC) = Vin/(RC), in which Vo refers to the output
-- voltage and Vin to the input voltage. In this demo we consider a
-- discrete time approximation of this system.
--
-- =Mathematical formulation
--
-- We consider a timestep @T@ which models the discretization of the
-- time. In this way, we denote @V[n]@ as discrete signal
-- approximating the continuous time signal @V(nT)@. The simplest
-- model for the derivative is a first order approximation in which
-- @V'[k] = 1/T * (V[k] - V[k-1])@.
--
-- Plugging this into the differential equation gives, after some
-- manipulation: Vo[k] = (T*R*C)/(T+RC)*(1/(R*C) * Vin[k] + 1/T * Vo[k-1]).
-- 
-- =ForSyDe modeling
--
-- The discrete time equation derived above suggests us that the
-- system should be able to remember the last output, that is, it is a
-- stateful system. We choose to model it by means of a mealySY
-- process contructor as the output depends on the state of the system
-- and on the input.
-- 
-- =Running the demo
-- 
-- To run the demo you need the
-- <http://hackage.haskell.org/package/ForSyDe ForSyDe package>
-- installed in your environment. For plotting, you need the
-- <http://gnuplot.sourceforge.net Gnuplot package>.
--
-- To calculate 10000 samples for R=1e3 Omhs, C=1e-6 F, T=1e-6run in @ghci@:
--
-- >>> simulate 1e3 1e-6 1e-6 10000
-- 
-- To plot the response for a square wave input, run in @ghci@:
--
-- >>> plotOutput 1e3 1e-6 1e-6 10000
-----------------------------------------------------------------------------

module ForSyDe.Shallow.Example.Synchronous.FlashADC where

import ForSyDe.Shallow

type Resistors = (Double, Double, Double, Double)
type Voltages = Signal Double
type Bits = (Bool, Bool, Bool)

-- | 'flashADC' is the top level module.
flashADC :: [Double]                    -- ^ Resistance values
          -> Signal Double              -- ^ Input signal
          -> Signal Integer             -- ^ Output signal
flashADC resistors input = decoder $ compNetwork input $ resNetwork resistors

-- | 'decoder' takes the thermometer code and outputs integers.
decoder :: [Signal Integer]             -- ^ Bit inputs
        -> Signal Integer               -- ^ Output signal
decoder = foldl1 (zipWithSY (+))

-- | 'compNetwork' implements the comparator array.
compNetwork :: Signal Double            -- ^ ADC input signal
            -> [Double]                 -- ^ Voltage thresholds
            -> [Signal Integer]         -- ^ Bit outputs
compNetwork input = zipWith (\i v -> mapSY (comparator v) i) (repeat input)

-- | 'comparator' is the one bit quantizer.
comparator :: Double                    -- ^ (+) input
           -> Double                    -- ^ (-) input
           -> Integer                   -- ^ Output
comparator i v
  | v <= i = 0
  | otherwise = 1

-- | 'resNetwork' implements the resistor voltage scaling network.
resNetwork :: [Double]                  -- ^ Resistor values
           -> [Double]                  -- ^ Threshold voltages
resNetwork resistors = init $ tail $ scanl (\v r -> v + vdd * r / (sumR)) 0 resistors
  where vdd = 1
        sumR = sum resistors


-- -- | 'simulate' takes the system parameters and dumps the step response.
-- simulate :: Double              -- ^ Resistance
--          -> Double              -- ^ Capacitance
--          -> Double              -- ^ Discretization timestep
--          -> Int                 -- ^ Number of samples
--          -> Signal Double       -- ^ Output signal
-- simulate r c t stop = rcFilter r c t $ (takeS stop ones)
--   where ones = 1.0:-ones

-- -- | 'plotOutput' uses the CTLib plot capabilities to plot the
-- -- outpu. In a later version, a plotter to Synchornous signals will be
-- -- developed.
-- plotOutput :: Double            -- ^ Resistance
--            -> Double            -- ^ Capacitance
--            -> Double            -- ^ Discretization timestep
--            -> Int               -- ^ Number of samples
--            -> IO String         -- ^ plot
-- plotOutput r c t stop = plotCT' (toRational t) [(output, "output")]
--   where output = d2aConverter DAhold (toRational t) $
--                  rcFilter r c t $ ((takeS stop ones) +-+ (takeS stop zeros))
--         ones = 1.0:-ones
--         zeros = 0.0:-zeros
