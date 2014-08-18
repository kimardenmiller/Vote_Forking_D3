forceChart = ( $compile, NodeEmitter, CollapsibleTreeLoader, FlattenVotingTree, AnimatingExperiments ) ->
  restrict: "EA"
  replace: true
  scope:
    options: '='
    hovered: '&hovered'

  link: (scope, element, attrs) ->
    root = []
    nodes = []
    links = []

    # Every force view gets its own ID.  This is used to scope ForceView instance-specific state onto the node Objects
    fvID = "_fv" + scope.options.initialID++

    # Set default size
    forceWidth = scope.options.width or angular.element(window)[0].innerWidth
    forceHeight = scope.options.height or angular.element(window)[0].innerHeight * .7

    scope._tick = ->
      scope.link
      .attr
          x1: (d) ->
            d.source.x
          y1: (d) ->
            d.source.y
          x2: (d) ->
            d.target.x
          y2: (d) ->
            d.target.y

      scope.node
      .attr
          transform: (d) ->
            "translate(" + d.x + "," + d.y + ")"
      .exit()
      .attr
          cx: (d) ->
            d.x
          cy: (d) ->
            d.y

    scope._setSelectionRadius = (selection) ->
      selection.attr "r", (d) ->
        return scope.options.radiusMeasure or 7

    scope._colorNode = (d) ->
      if d.isDemo then "#82b446" else "steelblue"

    # Toggle children on click.
    scope.collapseClick = (d) ->
      unless d3.event.defaultPrevented
        d.hidden = !d.hidden
        FlattenVotingTree scope, root
        update()

    window.onresize = ->
      forceWidth = angular.element(window)[0].innerWidth unless scope.options.width
      forceHeight = angular.element(window)[0].innerHeight unless scope.options.height
      scope.force.size([ forceWidth, forceHeight ])
      scope.visSvg
      .selectAll('.node')
      .remove()
      scope.render() if nodes.length > 0

    scope.visSvg = d3.select(element[0])
    .append("svg")
    .attr
        width: forceWidth
        height: forceHeight

    scope.visSvg
    .append("clipPath")
    .attr("id", "clip")
    .append("circle")
    .attr
        cx: 0
        cy: 0
        r: 15

    scope.force = d3
    .layout.force()
    .size([ forceWidth, forceHeight ])
    .linkDistance(scope.options.force.linkDistance)
    .charge(scope.options.force.charge)
    .linkStrength(.35)
    .friction(.85)
    .theta(.9)
    .gravity(.06)
    .on 'tick', scope._tick


    CollapsibleTreeLoader().then (json) ->
      root = json
      FlattenVotingTree scope, root
      scope.$watch 'options.currentNode', ->
        update()

    update = ->
      NodeEmitter scope
      if scope.nodesAndLinks
        nodes = scope.nodesAndLinks.nodes if scope.nodesAndLinks.nodes
        links = scope.nodesAndLinks.links if scope.nodesAndLinks.links
        scope.render() if scope.nodesAndLinks.nodes.length > 0

    scope.link = scope.visSvg
    .selectAll("line.link")

    scope.render = ->

      if scope.options.sliderReset
        scope.visSvg
        .selectAll('.node')
        .remove()
        scope.options.sliderReset = false

      if !nodes or nodes.length < 1
        console.log "No nodes present."
        return

      scope.force
      .nodes(nodes)
      .links(links)
      .start()

      # -------------------
      # Update the nodes...
      scope.node = scope.visSvg
      .selectAll("g.node")
      .data nodes, (d) ->
        d.id
      .attr
          "transform": (d) ->
            "translate(" + d.x + "," + d.y + ")"

      # If we're animating things out, they could be in the middle of their outbound animations.  Animate them back in.
      if scope.options.animateExit
        scope.node.each (d) ->
          delete d[fvID].isExitting
        .interrupt()
        .transition()
        .duration( scope.options.animateExit.msToFade / 2 )
        .style scope.options.enterAnimateStyle

      # Some may have already exitted but now they're back in the game.  Adjust their states.
      enterNodes = scope.node
      .enter()
      .append('svg:g')
      .each (d) ->
        d[fvID] = {}  unless d[fvID]
        if scope.options.enterAtParent and d.parent and d.parent.x
          d.x = d.px = d.parent.x
          d.y = d.py = d.parent.y
        else if scope.options.enterCenterJitter and d.type isnt 'hub' and scope.node[0][0].__data__.x
          d.x = d.px = scope.node[0][0].__data__.x + 2 * scope.options.enterCenterJitter * Math.random() - scope.options.enterCenterJitter
          d.y = d.py = scope.node[0][0].__data__.y + 2 * scope.options.enterCenterJitter * Math.random() - scope.options.enterCenterJitter
        else if d.type is 'hub'
          d.x = d.px = 50
          d.y = d.py = 50
        else
          d.x = d.px = forceWidth / 2
          d.y = d.py = forceHeight / 2
        delete d[fvID].isExitting
      .attr
          id: (d) ->
            d.id
          class: 'node'
      #'tooltip-append-to-body': true
      #tooltip: (d) ->
      #d.name
      #.call ->
      #$compile(this[0].parentNode)(scope)
      #console.log 'compile: '
      .call(scope._setSelectionRadius)
      .call(scope.force.drag).filter (d) ->
        not d.isDemo
      .on
          mouseover: (d) ->
            scope.hovered args: d
          mouseleave: ->
            scope.hovered args: 'leave'

      # append newly entering hub circles
      enterNodes
      .filter (d) ->
        d.type is 'hub'
      .append('circle')
      .attr
          class: 'hub'
      .style
          fill: 'DarkGray'
      .on
          click: scope.collapseClick

      # adjust the all hub circles
      scope.node
      .filter (d) ->
        d.type is 'hub'
      .selectAll('circle')
      .attr
          r: (d) ->
            d.size = nodes.length
            d.size * .8 + 15

      # newly entering hub labels
      enterNodes
      .filter (d) ->
        d.type is 'hub'
      .append("text")
      .attr
          class: 'hub label'
          dy: .5 + 'em'
      .text (d) ->
        d.name
      .on
          click: scope.collapseClick

      # adjust the all hub labels
      scope.node
      .filter (d) ->
        d.type is 'hub'
      .selectAll('text')
      .style
          'font-size': (d) ->
            d.size * .4 + 5 + 'px'
          color: 'black'

      # append newly entering topic circles
      enterNodes
      .filter (d) ->
        d.type is 'topic'
      .append('circle')
      .attr
          class: 'topic'
      .style
          fill: 'Chocolate'
      .on
          click: scope.collapseClick

      # adjust the all topic circles
      scope.node
      .filter (d) ->
        d.type is 'topic'
      .selectAll('circle')
      .attr
          r: (d) ->
            pLks = links.filter (l) ->
              l.source.id is d.id
            d.size = pLks.length
            vLks = []
            pLks.forEach (pl) ->
              vLks = links.filter (l) ->
                l.source.id is pl.target.id
            d.size = (d.size + vLks.length) / 2 + 15
            d.size

      # newly entering topic labels
      enterNodes
      .filter (d) ->
        d.type is 'topic'
      .append("text")
      .attr
          class: 'topic label'
          dy: .35 + 'em'
      .text (d) ->
        d.name
      .on
          click: scope.collapseClick

      # adjust the all topic labels
      scope.node
      .filter (d) ->
        d.type is 'topic'
      .selectAll('text')
      .style
          'font-size': (d) ->
            Math.sqrt(d.size) * 2 + 'px'

      # append newly entering proposal circles
      enterNodes
      .filter (d) ->
        d.type is 'proposal'
      .append('circle')
      .attr
          class: 'proposal'
      .style
          fill: scope._colorNode
      .on
          click: scope.collapseClick

      # adjust the all proposal circles
      scope.node
      .filter (d) ->
        d.type is 'proposal'
      .selectAll('circle')
      .attr
          r: (d) ->
            pLks = links.filter (l) ->
              l.source.id is d.id
            d.size = pLks.length * 3 + 10
            d.size

      # append newly entering proposal labels
      enterNodes
      .filter (d) ->
        d.type is 'proposal'
      .append("text")
      .text (d) ->
        d.name
      .attr
          class: 'proposal label'
          dy: .35 + 'em'
      .on
          click: scope.collapseClick

      # adjust the all proposal labels
      scope.node
      .filter (d) ->
        d.type is 'proposal'
      .selectAll('text')
      .style
          'font-size': (d) ->
            Math.sqrt(d.size) * 2 + 'px'

      #voter
      enterNodes
      .filter (d) ->
        d.type is 'voter'
      .append('image')
      .attr
          'xlink:href': (d) ->
            'http://graph.facebook.com/' + d.name + '/picture?'
          x: -20
          y: -20
          width: 40
          height: 40
      .style
          'clip-path': 'url(#clip)'

      #voter ring
      enterNodes
      .filter (d) ->
        d.type is 'voter'
      .append('circle')
      .attr
          class: 'voter-ring'
          r: 15
      .style
          stroke: 'DarkOliveGreen '
          'stroke-width': '.75'
          fill: 'none'

      # -------------------
      # Update the links...
      scope.link = scope.link
      .data links, (d) ->
        d.target.id

      # Enter any new links.
      enterLinks = scope.link
      .enter()
      .insert( "svg:line", ".node" )
      .attr
          class: 'link'
          x1: (d) ->
            d.source.x
          y1: (d) ->
            d.source.y
          x2: (d) ->
            d.source.x
          y2: (d) ->
            d.source.x


      # ------------------
      AnimatingExperiments scope, enterNodes, scope.node, enterLinks, scope.link
      # ------------------

      # Exits

      # Exit any old nodes.
      unless scope.options.animateExit
        console.log 'no animate exit: '
        scope.node.exit().remove()
        scope.node.exit().remove()
      else

        # Some exit nodes may have already started the exit animation.  Let them be, they'll be removed.
        # They're in the exit selection because they weren't in the list of nodes.
        # However, we still want them as part of the force view until they leave for sure.
      scope.node
      .exit()
      .filter (d) -> # remove the els when transition is done
        not d[fvID].isExitting
      .each (d) ->
        d[fvID].isExitting = true
        nodes.push d
      .interrupt()
      .transition()
      .duration(scope.options.animateExit.msToFade)
      .style(scope.options.exitAnimateStyle)
      .each 'end', (d) ->
        delete d[fvID].isExitting
      .remove()

      # Exit any old links.
      scope.link.exit().remove()

      scope.force
      .nodes(nodes)
      .links(links)
      .start()

App.Directives.directive 'forceChart', forceChart