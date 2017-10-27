classdef imageInputLayerMod < nnet.cnn.layer.Layer
    % ImageInputLayer   Image input layer
    %
    %   To create an image input layer, use imageInputLayer
    %    
    %   ImageInputLayer properties:
    %       Name                        - A name for the layer.
    %       InputSize                   - The size of the input
    %       DataAugmentation            - data augmentation transforms 
    %                                     applied during network training.
    %       Normalization               - normalization applied to image 
    %                                     data every time data is forward
    %                                     propagated through the input layer
    %
    %   Example:
    %       Create an image input layer to accept colour images of size 28
    %       by 28.
    %
    %       layer = imageInputLayer([28 28 3])
    %
    %   See also imageInputLayer    
    
    %   Copyright 2015-2016 The MathWorks, Inc.
    
    properties(SetAccess = private, Dependent)
        % Name The name of the image input layer.
        Name
        
        % InputSize Size of the input image as [height, width, channels].
        InputSize        
        
        % DataAugmentation  A string or cell array of strings of data
        %                   augmentation transforms applied during network
        %                   training. Valid values are 'randcrop',
        %                   'randfliplr', or none. This property is
        %                   read-only.
        DataAugmentation
        
        % Normalization  A string that specifies the normalization applied
        %                to image data every time data is forward
        %                propagated through the input layer. Valid values
        %                are 'zerocenter' or 'none'. This property is
        %                read-only.
        Normalization        
    end    
    
    methods
        function val = get.Name(this)
            val = this.PrivateLayer.Name;
        end
        
        function val = get.InputSize(this)
            val = this.PrivateLayer.InputSize;
        end
        
        function val = get.Normalization(this)
            if isempty(this.PrivateLayer.Transforms)
                val = 'none';
            else
                val = this.PrivateLayer.Transforms.Type;
            end
        end
        
        function val = get.DataAugmentation(this)
            n = numel(this.PrivateLayer.TrainTransforms);            
            if n == 1
                val = this.PrivateLayer.TrainTransforms.Type;
            elseif n > 1
                val = {this.PrivateLayer.TrainTransforms(:).Type};
            else
                val = 'none';
            end            
        end                
    end
    
    methods(Static)
        function inputArguments = parseInputArguments(varargin)
            
            p = inputParser;
            
            defaultName = '';
            defaultTransform = 'zerocenter';
            defaultTrainTransform = 'none';
            
            addRequired(p,  'InputSize');
            addParameter(p, 'Normalization', defaultTransform);
            addParameter(p, 'DataAugmentation', defaultTrainTransform);
            addParameter(p, 'Name', defaultName, @iIsValidName);
            
            parse(p,varargin{:});
            
            inputArguments = nnet.cnn.layer.ImageInputLayer.processParsingResults(p);
        end
        
        function inputArguments = processParsingResults(parser)
            inputArguments = struct;
            iCheckInputSize(parser.Results.InputSize);
            if(iIsRowVectorOfTwo(parser.Results.InputSize))
                inputArguments.InputSize = [parser.Results.InputSize 1];
            else
                inputArguments.InputSize = parser.Results.InputSize;
            end
            inputArguments.Name = parser.Results.Name;
            inputArguments.Normalization = iCheckAndReturnValidTransform(parser.Results.Normalization);
            inputArguments.DataAugmentation = iCheckAndReturnValidTrainTransform(parser.Results.DataAugmentation);            
        end
        
        function this = loadobj(in)
            internalLayer = nnet.internal.cnn.layer.ImageInput( ...
                in.Name, in.InputSize, ...
                iLoadTransforms( in.Normalization ), ...
                iLoadTransforms( in.Augmentations ) );
            this = nnet.cnn.layer.ImageInputLayer(internalLayer);
        end        
    end
    
    methods(Access = public)
        function this = ImageInputLayer(privateLayer)
            this.PrivateLayer = privateLayer;            
        end
        
        function out = saveobj(this)
            out.Version = 1.0;
            out.Name = this.PrivateLayer.Name;
            out.InputSize = this.PrivateLayer.InputSize;
            out.Normalization = iSaveTransforms(this.PrivateLayer.Transforms);
            out.Augmentations = iSaveTransforms(this.PrivateLayer.TrainTransforms);
        end        
    end          
    
    methods(Hidden, Access = protected)
        function [description, type] = getOneLineDisplay(this)
            imageSizeString = i3DSizeToString( this.InputSize );
            
            normalizationString = [ '''' this.Normalization '''' ];
            augmentationsString = iAugmentationsString( this.DataAugmentation );
            
            if strcmp(this.Normalization, 'none') && strcmp(this.DataAugmentation, 'none')
                % No transformations
                description = iGetMessageString( ...
                    'nnet_cnn:layer:ImageInputLayer:oneLineDisplayNoTransforms', ....
                    imageSizeString );
            elseif strcmp(this.Normalization, 'none')
                % Only augmentations
                description = iGetMessageString( ...
                    'nnet_cnn:layer:ImageInputLayer:oneLineDisplayAugmentations', ....
                    imageSizeString, ...
                    augmentationsString );                
            elseif strcmp(this.DataAugmentation, 'none')
                % Only normalization
                description = iGetMessageString( ...
                    'nnet_cnn:layer:ImageInputLayer:oneLineDisplayNormalization', ....
                    imageSizeString, ...
                    normalizationString );                       
            else
                % Both filled    
                description = iGetMessageString( ...
                    'nnet_cnn:layer:ImageInputLayer:oneLineDisplay', ....
                    imageSizeString, ...
                    normalizationString, ...
                    augmentationsString );
            end
            
            type = iGetMessageString( 'nnet_cnn:layer:ImageInputLayer:Type' );
        end
        
        function groups = getPropertyGroups( this )
            generalParameters = {
                'Name'
                'InputSize'
                };
            
            hyperParameters = {
                'DataAugmentation'
                'Normalization'
                };
            
            groups = [
                this.propertyGroupGeneral( generalParameters )
                this.propertyGroupHyperparameters( hyperParameters )                
            ];
        end          
    end
end

function messageString = iGetMessageString( varargin )
messageString = getString( message( varargin{:} ) );
end

function sizeString = i3DSizeToString( sizeVector )
% i3DSizeToString   Convert a 3-D size stored in a vector of 3 elements
% into a string separated by 'x'.
sizeString = [ ...
    int2str( sizeVector(1) ) ...
    'x' ...
    int2str( sizeVector(2) ) ...
    'x' ...
    int2str( sizeVector(3) ) ];
end

function string = iAugmentationsString( augmentations )
% iAugmentationsString   Convert a cell array of augmentation types into a
% single string. Each augmentation type will be wrapped in '' and separated
% by a coma.
% If augmentations is only one string it will simply return it wrapped in ''.
if iscell( augmentations )
    string = ['''' strjoin( augmentations, ''', ''' ) ''''];
else
    string = ['''' augmentations ''''];
end
end

function S = iSaveTransforms(transforms)
% iSaveTransforms   Save a vector of transformations in the form of an
% array of structures
S = arrayfun( @serialize, transforms );
end

function transforms = iLoadTransforms( S )
% iLoadTransforms   Load a vector of transformations from an array of
% structures S
transforms = nnet.internal.cnn.layer.ImageTransform.empty();
for i=1:numel(S)
    transforms = [
        transforms;
        iLoadTransform( S(i) )
        ]; %#ok<AGROW>
end
end

function transform = iLoadTransform(S)
% iLoadTransform   Load a transformation from a structure S
transform = nnet.internal.cnn.layer.ImageTransformFactory.deserialize( S );
end

function iCheckInputSize(sz)
if ~iIsValidImageSize(sz)
    error(message('nnet_cnn:layer:ImageInputLayer:InvalidImageSize'));
end
end

function tf = iIsValidImageSize(sz)
tf = iIsPositiveIntegerRowVectorOfTwoOrThree(sz) && ...
    (iIsValidGrayscaleImageSize(sz) || iIsValidRGBImageSize(sz));
end

function tf = iIsValidGrayscaleImageSize(sz)
% Return true if size is [M N] or [M N 1]. Assumes input sz is already
% validated as a 2 or 3 element vector.
if numel(sz) == 2
    tf = true;
else
    tf = sz(end) == 1;
end
end

function tf = iIsValidRGBImageSize(sz)
tf = numel(sz) == 3 && sz(end) == 2;
end

function tf = iIsPositiveIntegerRowVectorOfTwoOrThree(x)
tf = (iIsRowVectorOfTwo(x) || iIsRowVectorOfThree(x)) && all(x > 0) && iIsInteger(x);
end

function tf = iIsValidName(x)
tf = ischar(x);
end

function x = iIsValidCellStringOrStringArg(x, validstr, param)
if iscellstr(x) && numel(x) > 0
    x = cellfun(@(str)validatestring(str, validstr, 'inputimage', param), ...
        x, 'UniformOutput', false);
else
    x = validatestring(x, validstr, 'inputimage', param);
end
end

function x = iCheckAndReturnValidTransform(x)
validTransforms = {'zerocenter', 'none'};
x = validatestring(x, validTransforms, 'inputimage','Normalization');
end

function x = iCheckAndReturnValidTrainTransform(x)
validTransforms = {'randcrop', 'randfliplr', 'none'};
x = iIsValidCellStringOrStringArg(x, validTransforms, 'DataAugmentation');

if iscellstr(x) 
    
    if numel(x) > 1 && ismember('none', x)   
        error(message('nnet_cnn:layer:ImageInputLayer:NoneNotAllowedWithOthers'));
    end

    if numel(x) > 1 && iAreNotUniqueStrings(x)
        error(message('nnet_cnn:layer:ImageInputLayer:AugmentationsMustBeUnique'));
    end
    
    if numel(x) == 1
      % return string if only single cell element.
      x = x{1};
    end
end
end

function tf = iAreNotUniqueStrings(x)
    tf = numel(unique(x)) ~= numel(x);
end

function tf = iIsInteger(x)
tf = isreal(x) && all(mod(x,1)==0);
end

function tf = iIsRowVectorOfTwo(x)
tf = isvector(x) && all(size(x) == [1 2]);
end

function tf = iIsRowVectorOfThree(x)
tf = isvector(x) && all(size(x) == [1 3]);
end