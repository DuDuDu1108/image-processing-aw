classdef Experiment < handle
    properties
        data % An array of either Position or Colony objects
        meta_data % appropriate metadata object.
        maxpro_image_directory
        raw_image_directory
        experiment_type % Standard (std) or micropattern (mp)
%         imageNameStruct
        processing_parameters %for storing image processing
        % added by Siqi
        cond % condition string for each well
        cond_idx % corresponding idx for condition
        time % timepoint for each well (duration)
        time_idx % corresponding idx for time
        stain 
        stain_idx
        images_per_well
    end
    methods
        %constructor
        function this = Experiment(varargin)
            if nargin == 0
                return;
            end
            if nargin == 1
                this.raw_image_directory = varargin{1};
            end
        end
        %list methods here but functions are in separate files
        % (This isnt' required for the functions to run, but is useful)
        fileStruct = readRawDirectory(this) 
        filename = getFileNameFromStruct(this,imgNum)

    end
end