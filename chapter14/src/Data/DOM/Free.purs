module Data.DOM.Free
  ( Element()
  , Attribute()
  , Content()
  , AttributeKey()

  , a
  , div
  , p
  , img 

  , href
  , _class
  , src
  , width
  , height

  , (:=)
  , text
  , elem
  
  , render
  ) where

import Data.Maybe
import Data.Array (map)
import Data.String (joinWith)

import Control.Monad.Free
import Control.Monad.Writer
import Control.Monad.Writer.Class

newtype Element = Element
  { name         :: String
  , attribs      :: [Attribute]
  , content      :: Maybe (Content Unit)
  }

data ContentF a
  = TextContent String a
  | ElementContent Element a

instance functorContentF :: Functor ContentF where
  (<$>) f (TextContent s a) = TextContent s (f a)
  (<$>) f (ElementContent e a) = ElementContent e (f a)

newtype Content a = Content (Free ContentF a)

runContent :: forall a. Content a -> Free ContentF a
runContent (Content x) = x

instance functorContent :: Functor Content where
  (<$>) f (Content x) = Content (f <$> x)

instance applyContent :: Apply Content where
  (<*>) (Content f) (Content x) = Content (f <*> x)

instance applicativeContent :: Applicative Content where
  pure = Content <<< pure

instance bindContent :: Bind Content where
  (>>=) (Content x) f = Content (x >>= (runContent <<< f))

instance monadContent :: Monad Content

newtype Attribute = Attribute
  { key          :: String 
  , value        :: String
  }

newtype AttributeKey a = AttributeKey String

element :: String -> [Attribute] -> Maybe (Content Unit) -> Element
element name attribs content = Element
  { name:      name
  , attribs:   attribs
  , content:   content
  }

text :: String -> Content Unit
text s = Content $ liftF $ TextContent s unit

elem :: Element -> Content Unit
elem e = Content $ liftF $ ElementContent e unit

(:=) :: forall a. (Show a) => AttributeKey a -> a -> Attribute
(:=) (AttributeKey key) value = Attribute
  { key: key
  , value: show value
  }

a :: [Attribute] -> Content Unit -> Element
a attribs content = element "a" attribs (Just content)

div :: [Attribute] -> Content Unit -> Element
div attribs content = element "div" attribs (Just content)

p :: [Attribute] -> Content Unit -> Element
p attribs content = element "p" attribs (Just content)

img :: [Attribute] -> Element
img attribs = element "img" attribs Nothing

href :: AttributeKey String
href = AttributeKey "href"

_class :: AttributeKey String
_class = AttributeKey "class"

src :: AttributeKey String
src = AttributeKey "src"

width :: AttributeKey Number
width = AttributeKey "width"

height :: AttributeKey Number
height = AttributeKey "height"

render :: Element -> String
render (Element e) = 
  "<" ++ e.name ++
  " " ++ joinWith " " (map renderAttribute e.attribs) ++
  renderContent e.content

  where
  renderAttribute :: Attribute -> String
  renderAttribute (Attribute a) = a.key ++ "=\"" ++ a.value ++ "\""
  
  renderContent :: Maybe (Content Unit) -> String
  renderContent Nothing = " />"
  renderContent (Just (Content content)) = 
    ">" ++ execWriter (goM renderContentItem content) ++
    "</" ++ e.name ++ ">"
    where
    renderContentItem :: forall a. ContentF a -> Writer String a
    renderContentItem (TextContent s rest) = do
      tell s
      return rest
    renderContentItem (ElementContent e rest) = do
      tell $ render e
      return rest
