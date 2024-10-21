function strainmapping = STEMstrain(strainmapping)
% STEMstrain - determine the strain from coordinates
%
%   syntax: strainmapping = STEMstrain(strainmapping)
%       strainmapping  - strainMapping file
%

%--------------------------------------------------------------------------
% This file is part of StatSTEM
%
% Copyright: 2018, EMAT, University of Antwerp
% Author: K.H.W. van den Bos
% License: Open Source under GPLv3
% Contact: sandra.vanaert@uantwerpen.be
%--------------------------------------------------------------------------

coordinates = strainmapping.coordinates;
indices = strainmapping.indices;
types = strainmapping.typesN;
a = strainmapping.a;
error_a = strainmapping.errAP;
if isnan(error_a)
    error_a = 0;
end
b = strainmapping.b;
error_b = strainmapping.errBP;
if isnan(error_b)
    error_b = 0;
end
unit = strainmapping.projUnit;
teta = strainmapping.teta(1);
dirTeta_ab = strainmapping.dirTeta;

teta_ab = unit.ang;

% Rotation matrix
R = [cos(teta) -sin(teta);sin(teta) cos(teta)];

% Strain will be calculate in x- and y-direction of the image. For this
% calculation the a and b direction of the sample in view will be used.
% To calculate the strain components per individual atomic column the
% displacement with respect to the first columns in the a and b directions 
% will be used. Both positive and negative a and b directions are used to
% calculate a sort of average strain per point
Rab = [cos(dirTeta_ab*teta_ab) -sin(dirTeta_ab*teta_ab);sin(dirTeta_ab*teta_ab) cos(dirTeta_ab*teta_ab)];
Vstrain = [(R*[a;0])';(R*Rab*[b;0])'];

% Calculate error on strain matrix
Verror = [(R*[error_a;0])';(R*[0;error_b])'];
ad_bc = Vstrain(1,1)*Vstrain(2,2)-Vstrain(1,2)*Vstrain(2,1);
Errad_bc = sqrt(Vstrain(1,1)^2*Verror(2,2)^2 + Vstrain(2,2)^2*Verror(1,1)^2 + ...
    Vstrain(1,2)^2*Verror(2,1)^2 + Vstrain(2,1)^2*Verror(1,2)^2);

invad_bc = 1/ad_bc;
Errinvad_bc = sqrt( (-1/(ad_bc^2))^2*Errad_bc^2 );

Vstrain_re = [Vstrain(2,2) -Vstrain(1,2);-Vstrain(2,1) Vstrain(1,1)];
Verror_re = [Verror(2,2) -Verror(1,2);-Verror(2,1) Verror(1,1)];

% Error on inverse strain matrix
INVV = invad_bc*Vstrain_re;
ErrINVV = sqrt( (invad_bc^2*Verror_re.^2) + Vstrain_re.^2*Errinvad_bc^2 );

n1 = size(coordinates,1);
eps_xx = zeros(n1,2);
eps_xy = zeros(n1,2);
eps_yy = zeros(n1,2);
omg_xy = zeros(n1,2);
doubleInd = false(n1,1);
for n=1:n1
    u = zeros(2,2);
    e_u = zeros(2,2);
    v = zeros(2,2);
    e_v = zeros(2,2);
    
    if types(:,1)~=0
        % Find points in a direction
        ind = indices(:,1)==(indices(n,1)+1) & indices(:,2)==indices(n,2) & types(:,1)==types(n,1);
        if sum(ind)==1
            % Reference point exist
            u(1,:) = coordinates(ind,1:2) - coordinates(n,1:2) - Vstrain(1,:);
            e_u(1,:) = sqrt( Verror(1,:).^2 );
        else
            u(1,:) = [NaN;NaN];
            e_u(1,:)  = [NaN;NaN];
            % Store double coordinates
            if sum(ind)>1
                doubleInd(n,1) = true;
            end
        end

        % Find points in -a direction
        ind = indices(:,1)==(indices(n,1)-1) & indices(:,2)==indices(n,2) & types(:,1)==types(n,1);
        if sum(ind)==1
            % Reference point exist
            u(2,:) = coordinates(n,1:2) - coordinates(ind,1:2) - Vstrain(1,:);
            e_u(2,:) = sqrt( Verror(1,:).^2 );
        else
            u(2,:) = [NaN;NaN];
            e_u(2,:)  = [NaN;NaN];
            % Store double coordinates
            if sum(ind)>1
                doubleInd(n,1) = true;
            end
        end

        % If possible, average both displacements
        if any(isnan(u))
            u = u(~isnan(u(:,1)),:);
            e_u = e_u(~isnan(e_u(:,1)),:);
        else
            e_u = [sqrt( 1/2*u(1,1)^2*e_u(1,2)^2 + 1/2*u(1,2)^2*e_u(1,1)^2) sqrt( 1/2*u(2,1)^2*e_u(2,2)^2 + 1/2*u(2,2)^2*e_u(2,1)^2)];
            u = [mean(u(:,1)) mean(u(:,2))];
        end


        % Dind points in b direction
        ind = indices(:,1)==indices(n,1) & indices(:,2)==(indices(n,2)+1) & types(:,1)==types(n,1);
        if sum(ind)==1
            % Reference point exist
            v(1,:) = coordinates(ind,1:2) - coordinates(n,1:2) - Vstrain(2,:);
            e_v(1,:) = sqrt( Verror(2,:).^2 );
        else
            v(1,:) = [NaN;NaN];
            e_v(1,:)  = [NaN;NaN];
            % Store double coordinates
            if sum(ind)>1
                doubleInd(n,1) = true;
            end
        end

        % Find points in -b direction
        ind = indices(:,1)==indices(n,1) & indices(:,2)==(indices(n,2)-1) & types(:,1)==types(n,1);
        if sum(ind)==1
            % Reference point exist
            v(2,:) = coordinates(n,1:2) - coordinates(ind,1:2) - Vstrain(2,:);
            e_v(2,:) = sqrt( Verror(2,:).^2 );
        else
            v(2,:) = [NaN;NaN];
            e_v(2,:)  = [NaN;NaN];
            % Store double coordinates
            if sum(ind)>1
                doubleInd(n,1) = true;
            end
        end

        % If possible, average both displacements
        if any(isnan(v))
            v = v(~isnan(v(:,1)),:);
            e_v = e_v(~isnan(e_v(:,1)),:);
        else
            e_v = [sqrt( 1/2*v(1,1)^2*e_v(1,2)^2 + 1/2*v(1,2)^2*e_v(1,1)^2) sqrt( 1/2*v(2,1)^2*e_v(2,2)^2 + 1/2*v(2,2)^2*e_v(2,1)^2)];
            v = [mean(v(:,1)) mean(v(:,2))];
        end
    else
        u = [];
        v = [];
    end
    if ~isempty(u) && ~isempty(v)
        D = INVV*[u;v];
        Eerr = [sqrt( u(1)^2*ErrINVV(1,1)^2 + INVV(1,1)^2*e_u(1)^2 + v(1)^2*ErrINVV(1,2)^2 + INVV(1,2)^2*e_v(1)^2 ),...
            sqrt( u(2)^2*ErrINVV(1,1)^2 + INVV(1,1)^2*e_u(2)^2 + v(2)^2*ErrINVV(1,2)^2 + INVV(1,2)^2*e_v(2)^2 );...
            sqrt( u(1)^2*ErrINVV(2,1)^2 + INVV(2,1)^2*e_u(1)^2 + v(1)^2*ErrINVV(2,2)^2 + INVV(2,2)^2*e_v(1)^2 ),...
            sqrt( u(2)^2*ErrINVV(2,1)^2 + INVV(2,1)^2*e_u(2)^2 + v(2)^2*ErrINVV(2,2)^2 + INVV(2,2)^2*e_v(2)^2 )];
    else
        D = [NaN NaN;NaN NaN];
        Eerr = [NaN NaN;NaN NaN];
    end
    D = R\D;
    Eerr = R\Eerr;
    E = 1/2*(D+D');
    O = 1/2*(D-D');
    eps_xx(n,1) = E(1,1);
    eps_xy(n,1) = E(2,1);
    eps_yy(n,1) = E(2,2);
    omg_xy(n,1) = O(2,1);
    eps_xx(n,2) = Eerr(1,1);
    eps_xy(n,2) = sqrt( 0.5*Eerr(2,1).^2 + 0.5*Eerr(1,2).^2 );
    omg_xy(n,2) = Eerr(1,2);
    eps_yy(n,2) = Eerr(2,2);
end
if any(doubleInd)
    dI = find(doubleInd);
    str = '';
    for n=1:length(dI)
        str = [str,'(',num2str(coordinates(dI(n),1)),',',num2str(coordinates(dI(n),2)),')'];
        if n<length(dI)-1
            str = [str,', '];
        elseif n<length(dI)
            str = [str,' and '];
        end
    end
    warndlg(['Double coordinates found at: ',str]);
end

strainmapping.eps_xxP = eps_xx;
strainmapping.eps_yyP = eps_yy;
strainmapping.eps_xyP = eps_xy;
strainmapping.omg_xyP = omg_xy;