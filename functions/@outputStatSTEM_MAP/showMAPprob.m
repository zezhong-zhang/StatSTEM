function showMAPprob(obj)
% showMAPprob - Show the maximum a posteriori (MAP) probability curve
%
%   syntax: showMAPprob(obj)
%       obj - outputStatSTEM_MAP file

%--------------------------------------------------------------------------
% This file is part of StatSTEM
%
% Copyright: 2020, EMAT, University of Antwerp
% Author: K.H.W. van den Bos, J. Fatermans
% License: Open Source under GPLv3
% Contact: sandra.vanaert@uantwerpen.be
%--------------------------------------------------------------------------

if nargin<1
    return
end

if ~isempty(obj.GUI)
    ax = obj.ax;
else
    ax = gca;
end

pos = [0.1300 0.1100 0.7750 0.8150];
set(ax,'units','normalized','Position',pos)
hold off
plot(obj.N,obj.MAPprob,'.','MarkerSize',20,'color',[0 0 0]), xlabel('Number of atomic columns'),...
    ylabel('Relative probability (logscale)'),xticks(obj.N),hold on,...
    plot(obj.NselMod-1+obj.N(1),obj.MAPprob(obj.NselMod),'rx','MarkerSize',20);