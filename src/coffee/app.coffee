React = require 'react'
DOM = require 'react-dom'

MyComponent = React.createFactory require './components/MyComponent'

DOM.render MyComponent({
  message: 'Hello, awful blue world!' # change to test live reload
}), document.getElementById('app')
