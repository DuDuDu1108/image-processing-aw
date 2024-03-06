classdef MetadataMicropattern < Metadata
    % metadata with additional properties for Andor IQ output

    % ---------------------
    % Idse Heemskerk, 2016
    % ---------------------

    properties

        colRadiiMicron
        colRadiiPixel
        colMargin
    end

    methods

        function this = MetadataMicropattern(filename,skipPixSize)
            
            if ~exist("skipPixSize","var")
                skipPixSize = false;
            end

            this = this@Metadata(filename,skipPixSize);


            % default margin outside colony to process, in pixels
            this.colMargin = 10;
        end

        function this = setColRadiiPixel(this)
            if isempty(this.xres)  || isempty(this.colRadiiMicron)
                disp('Need to set .xres and .colRadiiMicron before running this function');
                return;
            end
            if isnumeric(this.colRadiiMicron)
                this.colRadiiPixel = this.colRadiiMicron/this.xres;
            elseif iscell(this.colRadiiMicron)
                this.colRadiiPixel = cell(size(this.colRadiiMicron,1),size(this.colRadiiMicron,2));
                for ii = 1:size(this.colRadiiMicron,2)
                    this.colRadiiPixel{1,ii} = cellfun(@(x) {x/this.xres}, this.colRadiiMicron{1,ii});
                end
            end
        end
        
    end
end