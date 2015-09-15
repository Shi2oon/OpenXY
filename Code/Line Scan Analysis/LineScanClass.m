classdef LineScanClass < handle
    properties
        Folder
        Filename
        Length
        Strain
        Settings
        SecInds
        Sections
        NumSections
        
        StrainStdDev
        TetStdDev
        SSE
    end
    methods
        function obj = LineScanClass(Folder,Filename)
        %Constructor
            if nargin == 0
                [Filename,Folder] = uigetfile('*.mat','Select an Analysis Params file');
            elseif nargin == 1
                [Folder,Filename,ext] = fileparts(Folder);
                Filename = [Filename, ext];
            end
            if exist(fullfile(Folder,Filename),'file')
                obj.Folder = Folder;
                obj.Filename = Filename;
            end
        end
        function ReadScan(obj)
        %Loads the Settings file and calculates the strain
            tempf = load(fullfile(obj.Folder,obj.Filename));
            if isfield(tempf,'Settings') && isfield(tempf.Settings,'data')
                obj.Settings = tempf.Settings;
                obj.Length = obj.Settings.ScanLength;
                obj.CalcStrain;
            end
            clear('tempf');
        end
        function CalcStrain(obj)
        %Extracts the strain components from the F-matrix
            if ~isempty(obj.Settings)
                u11 = zeros(obj.Settings.ScanLength,1);
                u22 = zeros(obj.Settings.ScanLength,1);
                u33 = zeros(obj.Settings.ScanLength,1);
                for i=1:obj.Settings.ScanLength
                    tempF(:,:)=obj.Settings.data.F{i};
                    [~, tempU]=poldec(tempF);
                    tempU=tempU-eye(3);
                    u33(i)=tempU(3,3); 
                    u22(i)=tempU(2,2);
                    u11(i)=tempU(1,1);
                end
                obj.Strain = [u11,u22,u33];
            end
        end
        function SecInds = SectionScan(obj)
        %Sections the Scan by mesa
            if ~isempty(obj.Settings)
                SecInds = SectionLineScan(obj.Strain);
                obj.SecInds = SecInds;
            else
                SecInds = 0;
            end
        end
        function AnalyzeSections(obj,SecInds,ExpTet)
        %Analyzes each section of the scan
            if ~isempty(obj.Settings)
                if nargin == 1
                    if isempty(obj.SecInds)
                        obj.SectionScan;
                    end
                    SecInds = obj.SecInds;
                end
                obj.Sections = struct2table(AnalyzeSections(obj.Strain,SecInds,ExpTet));
            end
        end
        function hg = plot(obj,varargin)
        %Overloaded plot function to plot the u11 strain in each section
            if ~isempty(obj.Sections)
                holdstate = ishold;
                if ~holdstate
                    cla
                end
                hold on
                hg = hggroup;
                for i = 1:size(obj.Sections,1)
                    plot(obj.Sections.Ind{i},obj.Sections.u11{i},varargin{:},'Parent',hg)
                    plot(obj.Sections.Ind{i},obj.Sections.u22{i},varargin{:},'Parent',hg)
                    plot(obj.Sections.Ind{i},obj.Sections.u33{i},varargin{:},'Parent',hg)
                end
                if ~holdstate
                    hold off
                end
            end
        end
        function h = plottet(obj,varargin)
            if ~isempty(obj.Sections)
                holdstate = ishold;
                if ~holdstate
                    cla
                end
                hold on
                for i = 1:size(obj.Sections,1)
                    h = plot(obj.Sections.Ind{i},obj.Sections.Tet{i},varargin{:});
                end
                if ~holdstate
                    hold off
                end
            end
        end
        function NumSections = get.NumSections(obj)
            NumSections = size(obj.Sections,2);
        end
        function StdDev = get.StrainStdDev(obj)
            if ~isempty(obj.Sections)
                StdDev(1) = mean(mean((obj.Sections{obj.Sections.ExpTet == 0,'Std'})));
                StdDev(2) = mean(mean((obj.Sections{obj.Sections.ExpTet ~= 0,'Std'})));
            else
                StdDev = [];
            end
        end
        function StdDev = get.TetStdDev(obj)
            if ~isempty(obj.Sections)
                StdDev(1) = mean((obj.Sections{obj.Sections.ExpTet == 0,'TetStd'}));
                StdDev(2) = mean((obj.Sections{obj.Sections.ExpTet ~= 0,'TetStd'}));
            else
                StdDev = [];
            end
        end
        function SSE = get.SSE(obj)
            if ~isempty(obj.Sections)
                SSE(1) = mean((obj.Sections{obj.Sections.ExpTet == 0,'SSE'}));
                SSE(2) = mean((obj.Sections{obj.Sections.ExpTet ~= 0,'SSE'}));
            else
                SSE = [];
            end
        end
            
    end
end
        