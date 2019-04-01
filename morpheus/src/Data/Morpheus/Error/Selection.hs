{-# LANGUAGE OverloadedStrings #-}

module Data.Morpheus.Error.Selection
  ( cannotQueryField
  , subfieldsNotSelected
  , selectionError
  , duplicateQuerySelections
  , hasNoSubfields
  ) where

import           Data.Morpheus.Error.Utils    (errorMessage)
import           Data.Morpheus.Types.Core     (EnhancedKey (..))
import           Data.Morpheus.Types.Error    (GQLError (..), GQLErrors, MetaError (..))
import           Data.Morpheus.Types.MetaInfo (MetaInfo (..))
import qualified Data.Text                    as T (Text, concat)

selectionError :: MetaError -> GQLErrors
selectionError (UnknownType meta)    = typeDoesNotExists meta
selectionError (UnknownField meta)   = cannotQueryField meta
selectionError (TypeMismatch meta _) = subfieldsNotSelected meta -- real type for this case

typeDoesNotExists :: MetaInfo -> GQLErrors
typeDoesNotExists meta = errorMessage (position meta) text
  where
    text = T.concat ["Unknown type \"", typeName meta, "\"."]

-- GQL: "Field \"default\" must not have a selection since type \"String!\" has no subfields."
hasNoSubfields :: MetaInfo -> GQLErrors
hasNoSubfields meta = errorMessage (position meta) text
  where
    text =
      T.concat
        ["Field \"", key meta, "\" must not have a selection since type \"", typeName meta, "\" has no subfields."]

cannotQueryField :: MetaInfo -> GQLErrors
cannotQueryField meta = errorMessage (position meta) text
  where
    text = T.concat ["Cannot query field \"", key meta, "\" on type \"", typeName meta, "\"."]

duplicateQuerySelections :: T.Text -> [EnhancedKey] -> GQLErrors
duplicateQuerySelections parentType = map keyToError
  where
    keyToError (EnhancedKey key' pos) = GQLError {desc = toMessage key', posIndex = [pos]}
    toMessage key' = T.concat ["duplicate selection of key \"", key', "\" on type \"", parentType, "\"."]

-- GQL:: Field \"hobby\" of type \"Hobby!\" must have a selection of subfields. Did you mean \"hobby { ... }\"?
subfieldsNotSelected :: MetaInfo -> GQLErrors
subfieldsNotSelected meta = errorMessage (position meta) text
  where
    text = T.concat ["Field \"", key meta, "\" of type \"", typeName meta, "\" must have a selection of subfields"]