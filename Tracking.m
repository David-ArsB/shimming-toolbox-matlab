classdef Tracking < matlab.mixin.SetGet
% TRACKING - Respiration/Field tracking for real-time shimming 
%
% Tracker = TRACKING(  )
%
%   Tracker contains fields
%
%       .Data 
%           .p 
%               data measurements themselves (e.g. pressure or navigator phase)
%           .t
%               (not implemented, but could be the sample times of .p)
%
%       .Specs
%           .dt 
%               sampling interval in units of ms?
%
% .......
%
%   Description
%
%
% =========================================================================
% Part of series of classes pertaining to shimming:
%
%    Tracking
%    ShimCal
%    ShimCom
%    ShimEval
%    ShimOpt
%    ShimSpecs
%    ShimTest 
%    ShimUse
%
% =========================================================================
% Updated::20170407::ryan.topfer@polymtl.ca
% =========================================================================

% *** TODO 
%
% ..... 
%
% =========================================================================

properties   
    Data ;
    Specs ;
end

% =========================================================================
% =========================================================================
methods
% =========================================================================
function Tracker = Tracking( Specs )
%TRACKING  

if nargin < 1
    Specs = [] ;
end

Tracker.Specs  = Specs ;
Tracker.Data   = [] ; 
Tracker.Data.p = [] ; 

end    
% =========================================================================
function [predictedMeasurement] = predictmeasurement( Tracker, delay, order )
% PREDICTMEASUREMENT

% if Params.extrapolationOrder == 1
%
if order == 1 || nargin == 2 % 1st order Taylor expansion
    predictedMeasurement = Tracker.Data.p(end) + ...
        delay*( Tracker.Data.p(end) - Tracker.Data.p( end - 1 ) )/(2*arduinoPeriod) ; 
    %     delay
    % /Shim.Opt.Probe.Specs.arduinoPeriod/1000)* ...
    %             (pressure(end) - pressure(end-1)) );

end

end
% =========================================================================

% =========================================================================
% =========================================================================
end
% =========================================================================
% =========================================================================
methods(Abstract)
% =========================================================================
[isTracking] = begintracking( Tracker )
%BEGINTRACKING 
% 
% (e.g. open com port)
%
% Returns true if successful. 

% =========================================================================
[] = stoptracking( Tracker )
%STOPTRACKING 
%
% (e.g. close com port)

% =========================================================================
[p] = getupdate( Tracker )
%GETUPDATE 
%
% Read in a single new tracking measurement (p) (e.g. from open com port)
%
% p = GETUPDATE( Tracker )


% =========================================================================
end


methods(Static)
% =========================================================================
function [measurementLog, sampleTimes] = loadmeasurementlog( measurementLogFilename, sampleTimesFilename )
%LOADMEASUREMENTLOG
% 
% Reads binary file of data measurements (e.g. pressure recording) to return
% vector(s) of doubles.
%
% measurementLog                = LOADMEASUREMENTLOG( measurementLogFilename ) ;
% [measurementLog, sampleTimes] = LOADMEASUREMENTLOG( measurementLogFilename, sampleTimesFilename )

if nargin < 1
    error( 'Insufficient arguments. Must provide full path to measurement log .bin file.' ) ;

else
    if nargin >= 1
        measurementLogFid = fopen( measurementLogFilename, 'r' ) ;
        measurementLog    = fread( measurementLogFid, inf, 'double' ) ;
        fclose( measurementLogFid );
    end

    if nargin == 2 
        sampleTimesFid = fopen( sampleTimesFilename, 'r' ) ;
        sampleTimes    = fread( sampleTimesFid, inf, 'double' ) ;
        fclose( sampleTimesFid );
    end
end

end
% =========================================================================
function [] = plotmeasurementlog( measurementLog, Params )
%PLOTMEASUREMENTLOG
%
% PLOTMEASUREMENTLOG( measurementLog ) ;
% PLOTMEASUREMENTLOG( measurementLog, Params )
%
% Supported fields to Params struct
%
%   .figureTitle
%       [default: 'Pressure log']
%
%   .sampleTimes
%       vector (length == length(measurementLog)) of sample times in seconds
%
%   .yLabel
%       [default: 'Pressure (kPa)']

DEFAULT_FIGURETITLE = 'Pressure log' ;
DEFAULT_YLABEL      = 'Pressure (kPa)' ;

if nargin < 1
    error( 'Insufficient arguments. Must provide measurement log vector.' ) ;
end

if nargin == 1 || isempty( Params ) 
    Params.dummy = [] ;
end

if ~myisfield( Params, 'figureTitle' ) || isempty( Params.figureTitle ) 
    Params.figureTitle = DEFAULT_FIGURETITLE ;
end

if ~myisfield( Params, 'yLabel' ) || isempty( Params.yLabel ) 
    Params.yLabel = DEFAULT_YLABEL ;
end

% ------- 
figure 

if myisfield( Params, 'sampleTimes' ) && ~isempty( Params.sampleTimes ) 
    plot( Params.sampleTimes, measurementLog, '+' ) ;
    xlabel('Time (s)');
else
    plot( measurementLog, '+' ) ;
    xlabel('Sample index');
end
    
title( Params.figureTitle ) ;
ylabel( Params.yLabel ) ;

end
% =========================================================================
function [medianMeasure] = userselectmedianmeasurement( measurementLog )
% USERSELECTMEDIANMEASUREMENT
%
%   medianMeasure = USERSELECTMEDIANMEASUREMENT( measurementLog ) 
%
%   Plots measurementLog and the user selects START and END (apnea) indices
%   over which to calculate the median. The median measurement is superposed
%   over the measurementLog graph and the user is asked if the result is 
%   satisfactory (or redo).

isUserSatisfied = false ;

while ~isUserSatisfied

    gcf ;
    plot( measurementLog, '+' ) ;
    title( 'Measure Log' ) ;
    
    xlabel('Sample index');
    ylabel('Amplitude');
    
    apneaStartIndex = ...
        input( ['Identify sample index corresponding to beginning of apnea ' ...
            '([Enter] selects sample 1): '] ) ;
    
    if isempty(apneaStartIndex)
        apneaStartIndex = 1;
    end

    apneaEndIndex = ...
        input( ['Identify sample index corresponding to end of apnea ' ...
            '([Enter] selects the last recorded sample): '] ) ;

    if isempty(apneaEndIndex)
       medianMeasure = ...
           median( measurementLog( apneaStartIndex : end ) ) ;
    else
       medianMeasure = ...
           median( measurementLog( apneaStartIndex : apneaEndIndex ) ) ;
    end

    gcf; 
    plot( measurementLog, '+' );
    hold on;
    plot( medianMeasure*ones( size( measurementLog ) ) ) ;
    title( 'Measure Log' ) ;
    xlabel('Sample index');
    ylabel('Amplitude');
    legend('Measure log','Median measurement over given interval');    
    hold off;

    response = input(['Is the current median estimate satisfactory?' ...
        '0 to re-enter the data range; 1 (or enter) to continue: ']) ;

     if ~isempty(response)
        isUserSatisfied = logical(response) ;
     else
         isUserSatisfied = true;
     end

end

end
% =========================================================================

end
% =========================================================================
% =========================================================================

end
