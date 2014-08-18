FireCtrl = ( $sce, $scope, $interval ) ->

  $scope.options =
    initialID: 1
    width: 960 # 960 Bl.ocks Default
    height: 440 # 600 Bl.ocks Default
    exitAnimateStyle:   #When nodes animate out of the force view, we animate them to these css params
      opacity: 0
    enterAnimateStyle:  #Opposite state of the exitAnimateStyle
      opacity: 1
    animateExit:
      msToFade: 750
    enterAtParent: true
    enterCenterJitter: 10
    min: 0
    currentNode: 0
    headLabel: 'Play'
    currentTs: undefined
    sliderReset: true
    radiusMeasure: 7
    force:
      charge: (n) ->
        n.forceViewCharge or -200
      linkDistance: (l) ->
        l.linkDistance or 200

  $scope.message = $sce.trustAsHtml('Press <b><em>Play</em></b> on left to start the visualization.')

  $scope.hovered = (d) ->
    if d is 'leave'
      $scope.hover = 'Hover, click or Drag any Node to see more.'
    else
      $scope.hover = d.type.charAt(0).toUpperCase() + d.type.substr(1).toLowerCase() + ': ' +
      switch
        when d.type is 'voter' then d.name
        when d.type is 'hub' then 'This would be your group'
        else d.text

    $scope.$apply()

  timer = undefined

  $scope.play = ->
    $scope.message = null
    $scope.hover = 'Hover, click or Drag any Node to see more.'
    if angular.isDefined(timer)
      $scope.pauseSlider()
    else
      $scope.options.headLabel = 'Pause'
      forward = true
      curVal = undefined
      dir = 1
      tick = ($scope.options.max - $scope.options.min) / 200
      timer = $interval(->
        curVal = Number($scope.options.currentNode) or $scope.options.min
        #dir = -6  if curVal + tick > $scope.options.max    # Logic to run the slider in reverse if you want it.
        if curVal - tick < $scope.options.min
          dir = 1
          $scope.options.sliderReset = true
        $scope.options.currentNode = curVal + dir * tick
        $scope.pauseSlider()  if curVal + tick > $scope.options.max
      , 400) # must be larger than debounce!

  $scope.pauseSlider = ->
    if angular.isDefined(timer)
      $interval.cancel timer
      $scope.options.headLabel = 'Play'
      timer = `undefined`

  $scope.$on "$destroy", ->
    $scope.pauseSlider()

window.App = angular.module('spokenvote', [  'spokenvote.services', 'spokenvote.directives', 'ui.bootstrap' ])
App.Directives = angular.module('spokenvote.directives', [])
App.Services = angular.module('spokenvote.services', ['ngResource'])

App.controller 'FireCtrl', FireCtrl