classdef Metadata
    % a class to create a uniform metadata interface
    
    % ---------------------
    % Idse Heemskerk, 2016
    % ---------------------
    
    properties
        
        filename
        
        %tPerFile
        
        xres                % x-resolution
        yres                % y-resolution
        xSize
        ySize
        
        nZslices
        
        nChannels           % number of channels
        channelNames        % cell array of channel names
        % when read by bioformats: detector name or dye
        excitationWavelength
        
        channelLabel        % names given to channels by hand,
        % e.g. labeled protein
        nuclearChannel % number of channel corresponding to nuclei
        
        nTime               % number of time points
        timeInterval
        ZTswapped           %T/F flag for whether z and t are swapped in bioformats
        
        nPositions
        montageOverlap      % percent overlap of montage
        montageGridSize     % grid size n by m locations
        XYZ                 % position coordinates
        
        raw                 % store unprocessed metadata if necessary
        
        % to keep track of multi-well experiments
        nWells              % number of well
        posPerCondition     % positions per well
        conditions          % cell array of condition labels
    end
    
    methods
        
        function this = Metadata(filename,skipPixSize)
            
            if nargin == 1
                this = this.read(filename);
                this.filename = filename;
            elseif nargin == 2
                 this = this.read(filename,skipPixSize);
            end
        end
        
        function this = read(this, filename,skipPixSize)
            % read metadata from file using bioformats
            %
            % read(filename)
            
            r = bfGetReader(filename);
            omeMeta = r.getMetadataStore();
            
            this.xSize = omeMeta.getPixelsSizeX(0).getValue();
            this.ySize = omeMeta.getPixelsSizeY(0).getValue();
            if ~exist('skipPixSize','var') || skipPixSize == false
                this.xres = double(omeMeta.getPixelsPhysicalSizeX(0).value);
                this.yres = double(omeMeta.getPixelsPhysicalSizeY(0).value);
            end
            dt = omeMeta.getPixelsTimeIncrement(0);
            if ~isempty(dt)
                this.timeInterval = double(dt.value);
            else
                this.timeInterval = [];
            end
            
            this.nChannels = r.getSizeC();
            this.channelNames = {};
            for ci = 1:this.nChannels
                this.channelNames{ci} = char(omeMeta.getChannelName(0,ci-1));
            end
            
            this.excitationWavelength = {};
            for ci = 1:this.nChannels
                lambda = omeMeta.getChannelExcitationWavelength(0,ci-1);
                if ~isempty(lambda)
                    this.excitationWavelength{ci} = round(10^3*double(lambda.value(ome.units.UNITS.MICROM)));
                end
            end
            
            this.nZslices = r.getSizeZ();
            this.nTime = r.getSizeT();
            
            %omeMeta.getPixelsType(0);
            
            this.raw = char(omeMeta.dumpXML());
        end
        
        function this = setAllMetaDefaults(this,magnification)
            meta.channelLabel = {'DAPI','Cdx2','Sox2','Bra'};
            meta.colRadiiMicron = [200 500 800 1000]/2;
            meta.colMargin = 10; % margin outside colony to process, in pixels
            s = round(20/meta.xres);
            adjustmentFactor = [];
        end
        
        function this = setDefaultResolution(this,magnification,zoom_value)
            
            if ~exist('magnification','var')
                magnification = '20X';
            end
            
            if ~exist('zoom_value','var')
                zoom_value = 1;
            end
            
            switch magnification
                case '10X'
                    this.xres = 1.25/zoom_value;
                    this.yres = 1.25/zoom_value;
                case '20X'
                    this.xres = 0.625/zoom_value;
                    this.yres = 0.625/zoom_value;
                case '30X'
                    this.xres = 0.4167/zoom_value;
                    this.yres = 0.4167/zoom_value;
                case '40X'
                    this.xres = 0.3125/zoom_value;
                    this.yres = 0.3125/zoom_value;
                case '60X'
                    this.xres = 0.2083/zoom_value;
                    this.yres = 0.2083/zoom_value;
                case '100X'
                    this.xres = 0.125/zoom_value;
                    this.yres = 0.125/zoom_value;
            end
            
        end
        
        function save(this)
            % save this object to a mat file
            %
            % save()
            %
            % e.g. raw filename is 1.oib -> stores metadata in same place
            % under 1_metadata.mat
            
            [datadir,barefname] = fileparts(this.filename);
            metafname = fullfile(datadir,[barefname '_metadata']);
            save(metafname, 'this');
        end
        
        function displayPositions(this)
            % display positions
            %
            % displayPositions();
            %
            % positions are center of field of view?
            
            XYZ = this.XYZ;
            
            %scatter(XYZ(:,1), XYZ(:,2))
            
            for i = 1:size(XYZ,1)
                text(XYZ(i,1), XYZ(i,2),num2str(i))
                w = 1024*this.xres;
                h = 1024*this.yres;
                rectangle('Position',[XYZ(i,1)-w/2,XYZ(i,2)-h/2,w,h])
            end
            axis([min(XYZ(:,1))-w max(XYZ(:,1))+w min(XYZ(:,2))-h max(XYZ(:,2))+h])
            axis equal
            axis off
            
            % XYZmean = mean(XYZ);
            % hold on
            % scatter(XYZmean(:,1), XYZmean(:,2),'r')
            % hold off
        end

    end
end