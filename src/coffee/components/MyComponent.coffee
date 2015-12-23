React = require 'react'

{h1} = React.DOM

module.exports = React.createClass
  displayName: 'MyComponent'

  propTypes:
    message: React.PropTypes.string.isRequired

  render: ->
    h1 {
      ref: 'header'
    }, @props.message
