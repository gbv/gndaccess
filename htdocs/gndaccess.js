angular.module('gndaccessApp',[])
  .controller('gndaccessCtrl', ['$scope','$http','$location',function($scope,$http,$location) {

    // get current list of formats from server
    $scope.formats = {};
    $http.get('formats.json').then(function(response) {
        $scope.formats = response.data;
    });

    // default format
    $scope.format = "aref";

    $scope.gnd = $location.hash();

    // similar services
    $scope.seealso = {
        "Entity Facts": "http://hub.culturegraph.org/entityfacts/",
        "Deutsche Digitale Bibliothek": "https://www.deutsche-digitale-bibliothek.de/entity/",
    };

    $scope.submitGND = function() {
        // remove query string and hash
        var base = window.location.href.split(/[?#]/)[0]; 
        window.location = base + $scope.gnd + "?format=" + $scope.format;
    };
    
    $scope.$watch('gnd',function(){
        var form = $scope.gnd_form;
        if (form.$valid && $scope.gnd) {
            $location.hash($scope.gnd);
            var url = $scope.gnd + '?format=aref';
            $http.get(url).then(function(response) {
                $scope.data = response.data;
            },function() {
                $scope.data = null;
            });
        }        
    });
}]);
