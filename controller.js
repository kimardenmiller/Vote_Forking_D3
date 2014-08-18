// Generated by CoffeeScript 1.6.3
(function() {
  var FireCtrl;

  FireCtrl = function($sce, $scope, $interval) {
    var timer;
    $scope.options = {
      initialID: 1,
      width: 960,
      height: 600,
      exitAnimateStyle: {
        opacity: 0
      },
      enterAnimateStyle: {
        opacity: 1
      },
      animateExit: {
        msToFade: 750
      },
      enterAtParent: true,
      enterCenterJitter: 10,
      min: 0,
      currentNode: 0,
      headLabel: 'Play',
      currentTs: void 0,
      sliderReset: true,
      radiusMeasure: 7,
      force: {
        charge: function(n) {
          return n.forceViewCharge || -200;
        },
        linkDistance: function(l) {
          return l.linkDistance || 200;
        }
      }
    };
    $scope.message = $sce.trustAsHtml('Press <b><em>Play</em></b> on left to start the visualization.');
    $scope.hovered = function(d) {
      if (d === 'leave') {
        $scope.hover = 'Hover, click or Drag any Node to see more.';
      } else {
        $scope.hover = d.type.charAt(0).toUpperCase() + d.type.substr(1).toLowerCase() + ': ' + (function() {
          switch (false) {
            case d.type !== 'voter':
              return d.name;
            case d.type !== 'hub':
              return 'This would be your group';
            default:
              return d.text;
          }
        })();
      }
      return $scope.$apply();
    };
    timer = void 0;
    $scope.play = function() {
      var curVal, dir, forward, tick;
      $scope.message = null;
      $scope.hover = 'Hover, click or Drag any Node to see more.';
      if (angular.isDefined(timer)) {
        return $scope.pauseSlider();
      } else {
        $scope.options.headLabel = 'Pause';
        forward = true;
        curVal = void 0;
        dir = 1;
        tick = ($scope.options.max - $scope.options.min) / 200;
        return timer = $interval(function() {
          curVal = Number($scope.options.currentNode) || $scope.options.min;
          if (curVal - tick < $scope.options.min) {
            dir = 1;
            $scope.options.sliderReset = true;
          }
          $scope.options.currentNode = curVal + dir * tick;
          if (curVal + tick > $scope.options.max) {
            return $scope.pauseSlider();
          }
        }, 400);
      }
    };
    $scope.pauseSlider = function() {
      if (angular.isDefined(timer)) {
        $interval.cancel(timer);
        $scope.options.headLabel = 'Play';
        return timer = undefined;
      }
    };
    return $scope.$on("$destroy", function() {
      return $scope.pauseSlider();
    });
  };

  window.App = angular.module('spokenvote', ['spokenvote.services', 'spokenvote.directives', 'ui.bootstrap']);

  App.Directives = angular.module('spokenvote.directives', []);

  App.Services = angular.module('spokenvote.services', ['ngResource']);

  App.controller('FireCtrl', FireCtrl);

}).call(this);
