{-# LANGUAGE QuasiQuotes #-}
import Text.Lucius
import qualified Data.Text.Lazy.IO as TLIO

-- Dummy render function
render = undefined

-- Our mixin, which provides a number of vendor prefixes.
transition val = 
    [luciusMixin|
        -webkit-transtion: #{val};
        -moz-transition: #{val};
        -ms-transition: #{val};
        -o-transition: #{val};
        transition: #{val};
    |]


-- Actual template
myCSS =
    [lucius|
        .some-class {
            ^{transition "all 4s ease"}
        }
    |]


main = TLIO.putStrLn $ renderCss $ myCSS render
