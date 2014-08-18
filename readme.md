<html ng-app="spokenvote">

<head>
    <meta charset="utf-8" />
</head>

<body class="well">
<div ng-controller="FireCtrl">
    <!-- <ng:include src="'fireflies-ng/fire.html'"></ng:include> -->
    <div style="width: 85%;">
        <!--<h2 style="margin-top: 0;">Vote Forking in Spokenvote </h2>-->
        <p>Visualization worked forked from <a href='http://sketchbook.onafloatingrock.com/fireflies/' target='_blank'> Dan Lopuch's Fireflies</a> written in Angular and D3 to model consensus progression through forking in <a href='http://www.spokenvote.org'>Spokenvote</a>.</p>
        <div style="width: 100%;">
            <div class="form" >
                <input type="range" ng-model="options.currentNode" min='0' max='71' >
            </div>
            <div>
                <h4 class="play">
                    <a href='#' ng-click='play()' tooltip-placement='right' tooltip='Click to start the conversation.'> {{ options.headLabel }} </a>
                </h4>
            </div>
            <div class="box">
                <h4 class='text' ng-show='hover'> {{ hover }}</h4>
                <h4 class='text' ng-show='message' ng-bind-html='message' ></h4>
            </div>
        </div>
    </div>
</div>
</body>

</html>
