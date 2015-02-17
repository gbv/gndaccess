angular.module('gndaccessApp',[])
  .controller('gndaccessCtrl', ['$scope','$http',function($scope,$http) {

    // get current list of formats from server
    $scope.formats = {};
    $http.get('formats.json').then(function(response) {
        $scope.formats = response.data;
    });

    // default format
    $scope.format = "aref";

    $scope.submitGND = function() {
        // remove query string and hash
        var base = window.location.href.split('?')[0]; 
        window.location = base + $scope.gnd + "?format=" + $scope.format;
    };

    $scope.$watch('gnd',function(){
        var form = $scope.gnd_form;
        if (form.$valid && $scope.gnd) {
            $http.get( $scope.gnd + '?format=aref' ).then(function(response) {
                $scope.aref = response.data;
            },function() {
                $scope.aref = null;
            });
        }        
//        console.log($scope.gnd_form.$dirty);
//        console.log($scope.gnd);
    });
}]);
