function grainID = CalcGrainID(Settings)
% Get grainID
Phases = unique(Settings.GrainVals.Phase);
NumPhases = length(Phases);
PhaseLattice = cell(NumPhases,1);
for i = 1:NumPhases
    M = ReadMaterial(Phases{i});
    PhaseLattice{i} = M.lattice;
end
% Check if phases with different lattices exist
if any(~strcmp(PhaseLattice{1},PhaseLattice))
    w = warndlg('Phases with different lattices exist. Grains will be identified using a cubic lattice.');
    uiwait(w,5)
    lattice = 'cubic';
else
    lattice = PhaseLattice{1};
end
angles = vec2map(Settings.Angles,Settings.Nx,Settings.ScanType);
mistol = Settings.MisoTol*pi/180;
MinGrainSize = 0;
clean = false;
grainID = findgrains(angles, lattice, clean, MinGrainSize, mistol)';
