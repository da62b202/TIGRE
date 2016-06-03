function [x,errorL2]= CGLS(proj,geo,angles,niter,varargin)
% CGLS_CBCT solves the CBCT problem using the conjugate gradient least
% squares
% 
%  CGLS_CBCT(PROJ,GEO,ANGLES,NITER) solves the reconstruction problem
%   using the projection data PROJ taken over ALPHA angles, corresponding
%   to the geometry descrived in GEO, using NITER iterations.
% 
%  CGLS_CBCT(PROJ,GEO,ANGLES,NITER,OPT,VAL,...) uses options and values for solving. The
%   possible options in OPT are:
% 
% 
%  'Init'    Describes diferent initialization techniques.
%             �  'none'     : Initializes the image to zeros (default)
%             �  'FDK'      : intializes image to FDK reconstrucition
%             �  'multigrid': Initializes image by solving the problem in
%                            small scale and increasing it when relative
%                            convergence is reached.
%             �  'image'    : Initialization using a user specified
%                            image. Not recomended unless you really
%                            know what you are doing.
%  'InitImg'    an image for the 'image' initialization. Avoid.

%% parse inputs'
opts=     {'Init','InitImg'};
defaults= [   1  ,    1 ];

% Check inputs
nVarargs = length(varargin);
if mod(nVarargs,2)
    error('CBCT:plotImgs:InvalidInput','Invalid number of inputs')
end

% check if option has been passed as input
for ii=1:2:nVarargs
    ind=find(ismember(opts,varargin{ii}));
    if ~isempty(ind)
        defaults(ind)=0;
    end
end

for ii=1:length(opts)
    opt=opts{ii};
    default=defaults(ii);
    % if one option isnot default, then extranc value from input
   if default==0
        ind=double.empty(0,1);jj=1;
        while isempty(ind)
            ind=find(isequal(opt,varargin{jj}));
            jj=jj+1;
        end
        val=varargin{jj};
    end
    
    switch opt
        case 'Init'
            x=[];
            if default || strcmp(val,'none')
                x=zeros(geo.nVoxel');
                continue;
            end
            if strcmp(val,'FDK')
                x=FDK_CBCT(proj,geo,angles);
                continue;
            end
            if strcmp(val,'multigrid')
                x=init_multigrid(proj,geo,angles);
                continue;
            end
            if strcmp(val,'image')
                initwithimage=1;
                continue;
            end
            if isempty(x)
               error('CBCT:CGLS_CBCT:InvalidInput','Invalid Init option') 
            end
            % % % % % % % ERROR
        case 'InitImg'
            if default
                continue;
            end
            if exist('initwithimage','var');
                if isequal(size(val),geo.nVoxel');
                    x=val;
                else
                    error('CBCT:CGLS_CBCT:InvalidInput','Invalid image for initialization');
                end
            end
        otherwise 
    end
end
%%

% //doi: 10.1088/0031-9155/56/13/004

r=proj-Ax(x,geo,angles,'ray-voxel');
p=Atb(r,geo,angles,'matched');
gamma=norm(p(:),2)^2;


errorL2=zeros(1,niter);
for ii=1:niter
     if ii==1;tic;end
    
    q=Ax(p,geo,angles,'ray-voxel');
    alpha=gamma/norm(q(:),2)^2;
    x=x+alpha*p;
    
    aux=proj-Ax(x,geo,angles,'ray-voxel'); %expensive, is there any way to check this better?
    errorL2(ii)=im3Dnorm(aux,'L2');
    if ii>1 && errorL2(ii)>errorL2(ii-1)
        % OUT!
       x=x-alpha*p;

       return; 
    end
    % If step is adecuatem, then continue withg CGLS
    r=r-alpha*q;
    
    s=Atb(r,geo,angles,'matched');
    gamma1=norm(s(:),2)^2;
    beta=gamma1/gamma;
    gamma=gamma1;
    p=s+beta*p;
    
   
     if ii==1;
        expected_time=toc*niter;   
        disp('CGLS');
        disp(['Expected duration  :    ',secs2hms(expected_time)]);
        disp(['Exected finish time:    ',datestr(datetime('now')+seconds(expected_time))]);   
        disp('');
     end


end




end