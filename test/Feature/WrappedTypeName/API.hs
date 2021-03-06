{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module Feature.WrappedTypeName.API
  ( api,
  )
where

import Data.Morpheus (interpreter)
import Data.Morpheus.Types
  ( ComposedSubField,
    Event,
    GQLRequest,
    GQLResponse,
    GQLRootResolver (..),
    GQLType (..),
    constRes,
    subscribe,
  )
import Data.Text (Text)
import GHC.Generics (Generic)

data Wrapped a b = Wrapped
  { fieldA :: a,
    fieldB :: b
  }
  deriving (Generic, GQLType)

data WA m = WA
  { aText :: () -> m Text,
    aInt :: Int
  }
  deriving (Generic, GQLType)

type Wrapped1 = Wrapped Int Int

type Wrapped2 = Wrapped (Wrapped Text Int) Text

data Query m = Query
  { a1 :: WA m,
    a2 :: Maybe Wrapped1,
    a3 :: Maybe Wrapped2
  }
  deriving (Generic, GQLType)

data Mutation m = Mutation
  { mut1 :: Maybe (WA m),
    mut2 :: Maybe Wrapped1,
    mut3 :: Maybe Wrapped2
  }
  deriving (Generic, GQLType)

data Channel
  = Channel
  deriving (Show, Eq)

type EVENT = Event Channel ()

data Subscription (m :: * -> *) = Subscription
  { sub1 :: ComposedSubField m Maybe WA,
    sub2 :: m (Maybe Wrapped1),
    sub3 :: m (Maybe Wrapped2)
  }
  deriving (Generic, GQLType)

rootResolver :: GQLRootResolver IO EVENT Query Mutation Subscription
rootResolver =
  GQLRootResolver
    { queryResolver = Query {a1 = WA {aText = const $ pure "test1", aInt = 0}, a2 = Nothing, a3 = Nothing},
      mutationResolver = Mutation {mut1 = Nothing, mut2 = Nothing, mut3 = Nothing},
      subscriptionResolver =
        Subscription
          { sub1 = subscribe [Channel] (pure $ constRes Nothing),
            sub2 = subscribe [Channel] (pure $ constRes Nothing),
            sub3 = subscribe [Channel] (pure $ constRes Nothing)
          }
    }

api :: GQLRequest -> IO GQLResponse
api = interpreter rootResolver
