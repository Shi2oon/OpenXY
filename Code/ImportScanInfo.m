function Settings = ImportScanInfo(Settings,name,path)

%Read Scan File
ScanPath = fullfile(path,name);
if ~isfield(Settings,'Angles') || ~strcmp(Settings.ScanFilePath,ScanPath)

    [ScanFileData,Settings.ScanParams] = ReadScanFile(ScanPath);

    %Initialize Variables
    Settings.ScanLength = size(ScanFileData{1},1);
    Settings.Angles = zeros(Settings.ScanLength,3);
    Settings.XData = zeros(Settings.ScanLength,1);
    Settings.YData = zeros(Settings.ScanLength,1);
    Settings.IQ = zeros(Settings.ScanLength,1);
    Settings.CI = zeros(Settings.ScanLength,1);
    Settings.Fit = zeros(Settings.ScanLength,1);

    %Read ScanFile Data into Settings
    Settings.Angles(:,1) = ScanFileData{1};
    Settings.Angles(:,2) = ScanFileData{2};
    Settings.Angles(:,3) = ScanFileData{3};
    Settings.XData = ScanFileData{4};
    Settings.YData = ScanFileData{5};
    Settings.IQ = ScanFileData{6};
    Settings.CI = ScanFileData{7};
    Settings.Fit = ScanFileData{10};
    Settings.ScanFilePath = ScanPath;
end

%Check ScanType
[~,~,ext] = fileparts(ScanPath);
if strcmp(ext,'.ang')
    check = true;
    if ~isempty(strfind(Settings.ScanParams.GridType,'Hex'))
        AutoType = 'Hexagonal';
    elseif ~isempty(strfind(Settings.ScanParams.GridType,'Sqr'))
        AutoType = 'Square';
    else
        check = false;
    end
    if check && ~strcmp(Settings.ScanType,AutoType)
        button = questdlg({'Scan type might be incorrect.';['Would you like to change it to ' AutoType '?']},'OpenXY');
        switch button
            case 'Yes'
                Settings.ScanType = AutoType;
            case 'Cancel'
                return;
        end
    end
    Settings.GrainMethod = 'Grain File'; %Default method
else
    Settings.GrainMethod = 'Find Grains'; %Only method available
end

%Unique x and y
X = unique(Settings.XData);
Y = unique(Settings.YData);

%Number of steps in x and y
Nx = length(X);
Ny = length(Y);

%Validate Scan Size
if ~strcmp(Settings.ScanType,'Hexagonal')
    if isfield(Settings.ScanParams,'NumColsOdd') && isfield(Settings.ScanParams,'NumRows')
        if Nx ~= Settings.ScanParams.NumColsOdd || Ny ~= Settings.ScanParams.NumRows
            
            NumColsOdd = Settings.ScanParams.NumColsOdd;
            NumRows = Settings.ScanParams.NumRows;
            ScanP = [num2str(NumColsOdd) 'x' num2str(NumRows)];
            Auto =  [num2str(Nx) 'x' num2str(Ny)];
            choice = questdlg({'Scan dimensions do not agree:';
                ['Scan File Header: ' ScanP];
                ['Unique values: ' Auto];
                'Select correct values'},'Scan Dimension Differ',ScanP,Auto,Auto);

            if strcmp(choice,ScanP)
                Nx = NumColsOdd;
                Ny = NumRows;
                set(ScanSizeText,'String',ScanP);
            else
                Settings.ScanParams.OriginalSize = [NumColsOdd, NumRows];
                Settings.ScanParams.NumColsOdd = Nx;
                Settings.ScanParams.NumColsEven = Nx - 1;
                Settings.ScanParams.NumRows = Ny;
            end
        end   
    end
    Settings.Nx = Nx; Settings.Ny = Ny;
else   
    if isfield(Settings.ScanParams,'NumColsOdd') && isfield(Settings.ScanParams,'NumRows')
        Settings.Nx = Settings.ScanParams.NumColsOdd;
        Settings.Ny = Settings.ScanParams.NumRows;
    else
        Settings.Nx = ceil(Nx/2); %NumRowsOdd
        Settings.Ny = Ny;
    end
end

%Get Grain and Phase Info
[Settings.grainID,Settings.Phase] = GetGrainInfo(ScanPath,Settings.Material,Settings.ScanParams,...
    Settings.Angles,Settings.MisoTol,Settings.GrainMethod,0); %Don't use cleanup
Settings.GrainVals.grainID = Settings.grainID;
Settings.GrainVals.Phase = Settings.Phase;

%Crop Scan
Settings = CropScan(Settings);
