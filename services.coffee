CollapsibleTree = ($resource) ->
  $resource 'collapsible.json'

CollapsibleTreeLoader = (CollapsibleTree, $q) ->
  ->
    delay = $q.defer()
    CollapsibleTree.get {}
    , (root) ->
      # Returns a list of all nodes under the root.
      delay.resolve root
    , ->
      delay.reject 'Unable to locate CollapsibleTree '
    delay.promise

FlattenVotingTree = ->
  ( scope, json ) ->
    recurse = (h) ->
      if h.type is 'hub'
        h.id = i++  unless h.id
        h.hidden = false unless h.hidden
        h.forceViewCharge = -900
        nodes.push h

        if h.children
          h.children.forEach (t) ->
            t.id = i++  unless t.id
            t.hidden = false unless t.hidden
            t.hiddenParent = h.hidden
            t.forceViewCharge = -400
            nodes.push t
            link =
              id: ++l
              source: h
              target: t
              linkDistance: 133
            links.push link

            if t.children
              t.children.forEach (p) ->
                p.id = i++  unless p.id
                p.hidden = false unless p.hidden
                if t.hidden is true or t.hiddenParent is true
                  p.hiddenParent = true
                else
                  p.hiddenParent = false
                p.forceViewCharge = -200
                nodes.push p
                link =
                  id: ++l
                  source: t
                  target: p
                  linkDistance: 100
                links.push link

                if p.children
                  p.children.forEach (v) ->
                    v.type = 'voter'
                    v.topicVoterId = t.id + '-' + v.name
                    v.parent = {}
                    v.id = i++  unless v.id
                    v.hidden = false unless v.hidden
                    if p.hidden is true or p.hiddenParent is true
                      v.hiddenParent = true
                    else
                      v.hiddenParent = false
                    v.forceViewCharge = -150
                    nodes.push v
                    link =
                      id: ++l
                      source: p
                      target: v
                      topicVoterId: t.id + '-' + v.name
                      linkDistance: 40
                    links.push link

    nodes = []
    links = []
    i = 0
    l = 0

    recurse json

    scope.options.max = links.length + 1
    scope.flattenedNodesAndLinks =
      nodes: nodes
      links: links

NodeEmitter = ->
  ( scope ) ->

    ts = scope.options.currentNode
    nodesAndLinks = scope.flattenedNodesAndLinks

    links = nodesAndLinks.links.filter (l) ->
      l.id < ts

    linksBytopicVoterId = _.chain(links)
    .sortBy(['topicVoterId', 'id'])
    .value()

    uniqLinksByTopic = []
    i = 0
    l = links.length

    while i < (l - 1)
      if linksBytopicVoterId[i + 1].topicVoterId and linksBytopicVoterId[i + 1].topicVoterId is linksBytopicVoterId[i].topicVoterId
        if linksBytopicVoterId[i + 1].hidden is undefined and linksBytopicVoterId[i].hidden is undefined and nodesAndLinks.nodes[linksBytopicVoterId[i + 1].target.id].parent
          nodesAndLinks.nodes[linksBytopicVoterId[i + 1].target.id].parent.x = nodesAndLinks.nodes[linksBytopicVoterId[i].target.id].x
          nodesAndLinks.nodes[linksBytopicVoterId[i + 1].target.id].parent.y = nodesAndLinks.nodes[linksBytopicVoterId[i].target.id].y
      else
        unless nodesAndLinks.nodes[linksBytopicVoterId[i].source.id].hidden is true or nodesAndLinks.nodes[linksBytopicVoterId[i].source.id].hiddenParent is true
          uniqLinksByTopic.push linksBytopicVoterId[i]
      i++
    unless i is 0 or nodesAndLinks.nodes[linksBytopicVoterId[i].source.id].hidden is true or nodesAndLinks.nodes[linksBytopicVoterId[i].source.id].hiddenParent is true
      uniqLinksByTopic.push linksBytopicVoterId[i]

    targets = _.chain(uniqLinksByTopic).pluck('target').pluck('id').value()

    nodes =
      nodesAndLinks.nodes.filter (d) ->
        if targets.length > 0
          d.id in targets or d.id is 0
        else if ts > 0
          d.type is 'hub'

    scope.nodesAndLinks =
      nodes: nodes
      links: uniqLinksByTopic

# experiments in animating
AnimatingExperiments = ->
  (scope, enterNodes, nodes, enterLinks, links) ->

    # ANIMATE NEW LINKS:
    # All new links: three step animation
    # 1) Initialize new links to red/transparent
    # 2) Transition, each with its staggered delay (but 0 transition length... just want the delay)
    # 3) When these end, suddenly make transparent, then create a new transition that fades in
    # (Note that transition.transition() doesn't work when the first transition is delayed... overrides it)
    i = 0
    enterLinks
    .style
        stroke: "red"
        opacity: 0
    .transition().delay (d) ->
      # In the enter selection, some elements are undefined.  Don't want to use argument[1] as i b/c it still
      # counts the undefineds.  Make our own i counter to get accurate "this is the i-th entering item" counts
        (i++) * 50  if d
    .duration( 0 )
    .each "end", (d) ->
      d3.select( "svg" )
      .selectAll( '.voter-ring' )
      .data [ d.target ], (d) ->
        d.id
      .style
          stroke: '#DC143C'
          'stroke-width': '2'
          opacity: .9
      .transition()
      .duration( 3500 )
      .style
          stroke: '#556B2F'
          'stroke-width': '1'
      .transition()
      .duration( 250 )
      .style
          opacity: 1

      d3.select( this )
      .style
          opacity: 1
      .transition()
      .duration( 750 )
      .style
          stroke: "#ddd"
          opacity: 1
#.transition().each (d) ->    # My force charges pretty good, but could expiriment with this method later
#d.source.nodeForceViewCharge = -1600
#scope.force.start()   # restart force view to make attractor change stick

App.Services.factory 'CollapsibleTree', CollapsibleTree
App.Services.factory 'CollapsibleTreeLoader', CollapsibleTreeLoader
App.Services.factory 'FlattenVotingTree', FlattenVotingTree
App.Services.factory 'NodeEmitter', NodeEmitter
App.Services.factory 'AnimatingExperiments', AnimatingExperiments