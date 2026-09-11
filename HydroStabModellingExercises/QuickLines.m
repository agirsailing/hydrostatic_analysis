% QuickLines
%
% Created by Anders Rosén, aro@kth.se.
%
% Syntax :
% [x,y,z,np,HP,yT,K] = QuickLines;
%
% Description :
% QuickLines can be used in an early ship design phase for quick generation of hull
% geometries. It allows selection of a parent britfair geometry file and import of
% it into Matlab. After that a dialog box and a number of figures appear on the screen.
% By changing the inputs in the dialog and pressing OK the geometry can be changed
% arbitrarily. See description of the various parameters below.
%
% The current geometry is displayed in the figures along with
% - the chosen draught, T;
% - the corresponding length Lq between the aft perpendicular (x=0) and the intersection
%   between the stem and the current waterline (Lq is hence equal to the length between
%   the perpendiculars (Lbp, Lpp) at the design draught);
% - the volume displacement, V;
% - the block coefficient, CB=V/(LqBT);
% - the longitudinal centre of bouyancy LCB measured from the aft perpendicular (x=0).
% Other hull particulars, like length, beam, etc are displayed in the input dialog
% and the command window. When a satisfactory result is achieved, type 1 in the last
% dialog input "Check out & save" and click Ok. You are now requested to save the new
% geometry as a new britfair file.
%
% Dialog inputs :
% Loa   - length over all, [meters].
% Bmax  - maximum beam ,[meters].
% Zmax  - maximum height of the hull (not necesarily =D), [meters].
% Zext  - a factor that allows you to add or subtract hight of the hull: Zext=1 means
%         no addition, 0<Zext<1 means subtraction, Zext>1 menas addition, [-].
% T     - draught for calculation of CB, V and LCB, [meters].
% Ka&Wa - parameters controlling distortion of the hull and thereby changing of CB and LCB,
%         by translation of the existing sections to new longitudinal positions.
%         The best way to understand these parameters is probably to play around and
%         make changes in the input and see how it affects the Distortion Form
%         Function and how the sections translate in the perspective view of the ship,
%         where the undistorted hull is pictured by grey sections and the distorted is
%         pictured with blue. See further descriptions of Ka, Wa, Kf and Wf below!
% Ka    - maximum translation [meters] in the aft half of the hull, i.e. the peak of the Distortion
%         Form Function. Hence, Ka<0 means that the sections in the aft half of the ship are
%         translated backwards resulting in a more full bodied hull (higher CB), while Ka>0
%         moves the sections forward making the hull more slender (lower CB).
% Wa    - a weight which determines if the hull should mainly be distorted (i.e. sections
%         translated) close to midship (W<0.5) or at the ends (W>0.5), i.e. the shape of
%         the Distortion Form Function.
% Kf,Wf - same as Ka and Wa but for the fore half of the hull. Note that Kf>0 makes the hull
%         more full bodied (increase CB) while Kf<0 makes the hull more slender.
% Check - input =0 allows for another change of the geometry, =1 exits the hull geometry
%         modelling and allows saving of the modified hull.
%
% Function outputs :
% x,y,z - matrices with hull offsets, [metres], where each column represents one half-section.
%         Hence, the coordinates of offset point number I counted from the keel, on section
%         number J counted from the aft, are (x(I,J),y(I,J),z(I,J)). x is the
%         longitudinal coordinate, positive forward; y is the transversal coordinate, positive
%         to port (left); z is the vertical coordinate positive upwards.
% np    - vector indicating the number of offsets for each section, i.e. how many of the
%         elements in each column of x,y&z that actually are offsets (different sections can
%         have different number of offsets).
% HP    - Vector with various outputs
%       - HP(1): Lq, [m] (see description above!)
%       - HP(2): Length Overall, [m]
%       - HP(3): Beam, [m]
%       - HP(4): Depth at CL, [m]
%       - HP(5): Draught, [m]
%       - HP(6): Summer Load Draught, [m]
%       - HP(7): Stern Overhang, [m]
%       - HP(8): Stem Overhang, [m]
%       - HP(9): Max Z Point, [m]
%       - HP(10): Min Z Point, [m]
%       - HP(11): CB, block coefficient, [-], =HP(13)/(HP(1)*HP(3)*HP(5))
%       - HP(12): LCB, longitudinal centre of buoyancy measured from the aft perpendicular, [m], corresponding to HP(5)
%       - HP(13): V, volume displacement, [m^3], corresponding to HP(5)
% yT    - array with y-coordinates for the waterline at draught HP(5). Corresponding to x-coordiantes x(1,:).
% K     - matrix keeping track of knuckles in the britfairfile

function [x,y,z,np,HP,yT,K] = QuickLines;

close all;

global OF1 OF2 OF3 OF4;

[x,y,z,np,K,namn] = ReadBritfair;

%qx=x; qy=y; qz=z;

scrsz = get(0,'ScreenSize');		%[left,bottom,width,height]
OF1 = figure('Position',[scrsz(3)/1.44-10  scrsz(2)/0.9+45 scrsz(3)/3.3 scrsz(4)/1.15]); hold on;
OF2 = figure('Position',[scrsz(1)+10  scrsz(4)*0.64 scrsz(3)/3.3 scrsz(4)/3.5]);
OF3 = figure('Position',[scrsz(1)+10  scrsz(4)/2.9 scrsz(3)/3.3 scrsz(4)/5.2]);
OF4 = figure('Position',[scrsz(1)+10  scrsz(4)*0.04 scrsz(3)/3.3 scrsz(4)/4.8]);

M0        = [max(max(x))-min(min(x))  2*(max(max(y))-min(min(y)))  max(max(z))-min(min(z)) 1 (max(max(z))-min(min(z)))/2 0 0.5 0 0.5 0];
M         = M0;
np0       = np;
[LBT,V,CB,LCB,yT] = Acalc(x,y,z,np,M(5));

figure(OF1); subplot(3,1,1); hold off; Typ='k.-';  PlotBodyPlan(x,y,z,np,LBT,Typ);  plot([-LBT(2)/2 LBT(2)/2],[LBT(3) LBT(3)]);
% figure(OF1); subplot(3,1,1); hold off; Typ='.-';  PlotBodyPlan(x,y,z,np,LBT,Typ);  plot([-LBT(2)/2 LBT(2)/2],[LBT(3) LBT(3)]);
title(['T [m]:' num2str(M(5),3) ' ; Lq [m]: ' num2str(LBT(1),3) ' ; V [m^3/10^3]: ' num2str(V/1000,2) ' ; CB [-]: ' num2str(CB,2) ' ; LCB [m]: ' num2str(LCB,2)]);
figure(OF2); hold off; Typ='k-';  PlotBodyPlan(x,y,z,np,LBT,Typ);   title('Body plan'); grid on; if length(diff(diff(x(1,:)))>1); title('Body plan (Note! Sections might be non-equidistant)'); end
% figure(OF2); hold off; Typ='-';  PlotBodyPlan(x,y,z,np,LBT,Typ);   title('Body plan'); grid on; if length(diff(diff(x(1,:)))>1); title('Body plan (Note! Sections might be non-equidistant)'); end
Plotta(x,y,z,np);
figure(OF1); subplot(3,1,3);  plot(x(1,:),zeros(size(x(1,:)))); axis tight; title('Distortion Form Function'); xlabel('x [m]'); ylabel('section translation [m]');


while M(10)==0
    dlg_title = ['Hull Modelling :'];
    prompt    = {['Loa [m] :'],['Bmax [m] :'],['Zmax [m] :'],'Zext [-] :','T [m] :','Ka [m] :','Wa (0<=Wa<=1) :','Kf [m] :','Wf (0<=Wf<=1) :','Check out & save (0=no, 1=yes) :'};
    num_lines = 1;
    default   = {num2str(M(1)),num2str(M(2)),num2str(M(3)),num2str(M(4)),num2str(M(5)),num2str(M(6)),num2str(M(7)),num2str(M(8)),num2str(M(9)),num2str(M(10))};
    %default   = {num2str(M(1),3),num2str(M(2),3),num2str(M(3),3),num2str(M(4),3),num2str(M(5),3),num2str(M(6),3),num2str(M(7),3),num2str(M(8),3),num2str(M(9),3),num2str(M(10),3)};
    answer    = inputdlg(prompt,dlg_title,num_lines,default);
    M         = str2num(char(answer));
    
    qx=x; qy=y; qz=z;
    
    if M(4)~=1
        [qx,qy,qz,np] = Zextention(x,y,z,np0,M);
        M0(3) = max(max(qz))-min(min(qz));
    end
    
    qx = qx*M(1)/M0(1);  qy = qy*M(2)/M0(2);  qz = qz*M(3)/M0(3);
    
    for J=1:size(qx,2)
        if M(5)>0.99*max(qz(1:np(J),J))
            M(5)=0.99*max(qz(1:np(J),J));
            h=warndlg('Too large draught!','!!!Warning!!!');
            uiwait(h);
        end
    end
    
    [qx,qy,qz] = HullDistortion(qx,qy,qz,np,M);
    
    [LBT,V,CB,LCB,yT] = Acalc(qx,qy,qz,np,M(5));
    
    figure(OF1); subplot(3,1,1); hold off; Typ='k.-';  PlotBodyPlan(qx,qy,qz,np,LBT,Typ);    plot([-LBT(2)/2 LBT(2)/2],[LBT(3) LBT(3)]);
%     figure(OF1); subplot(3,1,1); hold off; Typ='.-';  PlotBodyPlan(qx,qy,qz,np,LBT,Typ);    plot([-LBT(2)/2 LBT(2)/2],[LBT(3) LBT(3)]);
    title(['T [m] :' num2str(M(5),3) ' ; Lq [m]: ' num2str(LBT(1),3) ' ; V [m^3/10^3]: ' num2str(V/1000,2) ' ; CB [-]: ' num2str(CB,2) ' ; LCB [m]: ' num2str(LCB,2)]);
    figure(OF2); hold off; Typ='k-';  PlotBodyPlan(qx,qy,qz,np,LBT,Typ); title('Body plan'); grid on;
%     figure(OF2); hold off; Typ='-';  PlotBodyPlan(qx,qy,qz,np,LBT,Typ); title('Body plan'); grid on;
    
    SternOverhang = abs(qx(1,1));
    StemOverhang  = M(1)-LBT(1)-SternOverhang;
    HP = [LBT(1) M(1) M(2) max(qz(:,round(size(qx,2)/2))) LBT(3) LBT(3) SternOverhang StemOverhang M(3)-min(min(qz)) min(min(qz)) CB LCB CB*LBT(1)*LBT(2)*LBT(3)];
    HP = round(HP*100)/100;
    %LBT(1) = M(1)-2*Overhang;
    %HP = [LBT(1) M(1) M(2) max(qz(:,round(size(qx,2)/2))) LBT(3) LBT(3) Overhang Overhang M(3)-min(min(qz)) min(min(qz)) CB LCB CB*LBT(1)*LBT(2)*LBT(3)];
    
    disp(' ');
    disp(['Lq =  '                  num2str(HP(1),5) ' [m]']);
    disp(['Length Overall, Loa =  ' num2str(HP(2),5) ' [m]']);
    disp(['Beam, B =  '             num2str(HP(3),5) ' [m]']);
    disp(['Depth at CL =  '         num2str(HP(4),5) ' [m]']);
    disp(['Draught, T =  '          num2str(HP(5),5) ' [m]']);
    disp(['Summer Load Draught =  ' num2str(HP(6),5) ' [m]']);
    disp(['Stern Overhang =  '      num2str(HP(7),5) ' [m]']);
    disp(['Stem Overhang =  '       num2str(HP(8),5) ' [m]']);
    disp(['Max Z Point =  '         num2str(HP(9),5) ' [m]']);
    disp(['Min Z Point =  '         num2str(HP(10),5) ' [m]']);
    disp(['CB =  '                  num2str(HP(11),5) ' [-]']);
    disp(['LCB =  '                 num2str(HP(12),5) ' [m]']);
    disp(['V =  '                   num2str(HP(13),5) ' [m^3]']);
    disp(['US t =  '                   num2str(HP(13)*1.1023,5) ' [m^3]']);
    disp(['Note:']);
    disp(['Lq is the length between the aft perpendicular (x=0) and']);
    disp(['the intersection between the stem and the current waterline,']);
    disp(['i.e. Lq=Lpp for T=design draught.']);
    disp(['CB is calculated as V/(Lq*B*T).']);
    disp(['LCB is measured from the aft perpendicular.']);
    %pause;
end

x=qx; y=qy; z=qz;
WriteBritfair(x,y,z,np,K,HP,namn);
return;


% ----- Zextention -------------------------------------------------------------------------
function [qx,qy,qz,np]=Zextention(x,y,z,np,M);
global OF1 OF2 OF3 OF4;
qx=zeros(size(x,1)+1,size(x,2)); qy=zeros(size(x,1)+1,size(x,2)); qz=zeros(size(x,1)+1,size(x,2));
Te = max(max(z))*M(4);
spant=[];
for J=1:size(x,2)
    q1 = find(z(1:np(J),J)<Te);
    if isempty(q1)
        %bort = [bort J];
    elseif length(q1)<np(J)
        n     = length(q1);
        k     = (y(n+1,J)-y(n,J))/(z(n+1,J)-z(n,J));
        zT(J) = Te;
        yT(J) = k*(zT(J)-z(n,J))+y(n,J);
        np(J) = n+1;
        y(1:np(J),J) = [y(1:n,J);yT(J)]; z(1:np(J),J) = [z(1:n,J);zT(J)];
        spant = [spant J];
    elseif length(q1)==np(J)
        N = np(J)+1;
        y(1:N,J)  = [y(1:np(J),J);y(np(J),J)]; z(1:N,J) = [z(1:np(J),J);Te];
        x(1:N,J)  =[x(1,J);x(1:np(J),J)];
        np(J)     = N;
        spant     = [spant J];
    end
    qx(1:np(J),J) = x(1:np(J),J); qy(1:np(J),J)=y(1:np(J),J); qz(1:np(J),J)=z(1:np(J),J);
    %qx=x(:,spant); qy=y(:,spant); qz=z(:,spant);
end
qx=qx(:,spant); qy=qy(:,spant); qz=qz(:,spant);
return;
% ------------------------------------------------------------------------------------------


% ----- distort ----------------------------------------------------------------------------
function [x1,y1,z1,LBT,CB,LCB]=HullDistortion(x,y,z,np,M);
global OF1 OF2 OF3 OF4;

x1=x; y1=y; z1=z; LBT=[]; Te=[]; CB=[]; LCB=[];
%Lq = max(max(x));
Lq = max(max(x))+abs(min(min(x)));               %test 060828
pa = 0;
pf = 0;

if M(6)~=0 | M(8)~=0
    Te=M(5); Ka=M(6); Wa=M(7); Kf=M(8); Wf=M(9);
    if Wa<0.5;  mna=[2 6]-Wa*2*[0 4]; elseif Wa>=0.5; mna=[2 2]+(Wa-0.5)*[8 0]; end
    if Wf<0.5;  mnf=[2 6]-Wf*2*[0 4]; elseif Wf>=0.5; mnf=[2 2]+(Wf-0.5)*[8 0]; end
    
    %qa = find(x(1,:)>=0 & x(1,:)<=(Lq/2));
    qa = find(x(1,:)<=(Lq/2));                   %test 060828
    ea = -(x(1,qa)-max(x(1,qa))); ea = ea/max(ea);
    e=ea; m=mna(1); n=mna(2); p=pa; K=Ka;
    de = ((e-p).^m).*((1-e).^n); de(find(e<p))=0;   de = K*de/max(de);  da = de;
    
    %qf = find(x(1,:)>=Lq/2 & x(1,:)<=Lq);
    qf = find(x(1,:)>Lq/2);                      %test 060828
    ef = (x(1,qf)-min(x(1,qf))); ef = ef/max(ef);
    e=ef; m=mnf(1); n=mnf(2); p=pf; K=Kf;
    de = ((e-p).^m).*((1-e).^n);  de(find(e<p))=0;  de = K*de/max(de);  df = de;
    
    x1(:,qa) = x(:,qa) + ones(size(x(:,qa)))*diag(da);
    x1(:,qf) = x(:,qf) + ones(size(x(:,qf)))*diag(df);
    
    koll=find(diff(x1(1,:))>=0);
    if length(koll)<(size(x1,2)-1) || abs(Ka)>Lq/10 || abs(Kf)>Lq/10;
        h=warndlg('Very large distortions!','!!!Warning!!!');
        uiwait(h);
    end
    
    % --- plot form function ---
    ea=1:-0.01:0; e=ea; m=mna(1); n=mna(2); p=pa; K=Ka;
    de = ((e-p).^m).*((1-e).^n);  de(find(e<p))=0;  de = K*de/max(de);  da = de;
    ef=0:0.01:1; e=ef; m=mnf(1); n=mnf(2); p=pf; K=Kf;
    de = ((e-p).^m).*((1-e).^n);  de(find(e<p))=0;  de = K*de/max(de);  df = de;
    qa = find(x(1,:)<=(Lq/2));                   %test 060828
    qf = find(x(1,:)>Lq/2);                      %test 060828
    %qa = find(x(1,:)>=0 & x(1,:)<=Lq/2);
    %qf = find(x(1,:)>=Lq/2 & x(1,:)<=Lq);
    ex = Lq*(0:(length(ea)+length(ef)-1))/(length(ea)+length(ef)-1);
    figure(OF1); subplot(3,1,3);
    plot(ex,[da df]); axis tight; title('Distortion Form Function'); xlabel('x [m]'); ylabel('section translation [m]');
    % --------------------------
end

% --- plot perspective ---
figure(OF1); subplot(3,1,2); hold off;
for J=1:size(x,2)
    Q = 1:np(J);
    plot3(x(Q,J),y(Q,J),z(Q,J),'Color',[.8 .8 .8]); hold on;
    plot3(x(Q,J),-y(Q,J),z(Q,J),'Color',[.8 .8 .8]);
    %hline2 = line(t+.06,sin(t),'LineWidth',4,'Color',[.8 .8 .8]);
end
for J=1:size(x,2)
    Q = 1:np(J);
    plot3(x1(Q,J),y1(Q,J),z1(Q,J),'k.-'); hold on;
    plot3(x1(Q,J),-y1(Q,J),z1(Q,J),'k.-');
end
axis equal; axis tight; xlabel('x [m]');ylabel('y [m]');zlabel('z [m]'); view([50 25]); %view([120 20]);
% --------------------------

return;
% ------------------------------------------------------------------------------------------


% ----- calculate --------------------------------------------------------------------------
function [LBT,V,CB,LCB,yT] = Acalc(x,y,z,np,Te);
global OF1 OF2 OF3 OF4;

JT=[]; CB=[]; LCB=[]; yT=zeros(1,size(x,2)); zT=zeros(1,size(x,2));

% ----- wet section area -----
for J=1:size(x,2)
    q1 = find(z(1:np(J),J)<Te);
    if isempty(q1)
        A(J)=0;
    else
        JT    = [JT J];
        n     = length(q1);
        k     = (y(n+1,J)-y(n,J))/(z(n+1,J)-z(n,J));                    %direction from (yn,zn) to (yn+1,zn+1)
        zT(J) = Te;                                                     %z for new offset in waterline intersection
        yT(J) = k*(zT(J)-z(n,J))+y(n,J);                                %y for new offset in waterline intersection
        yq    = [y(1:n,J);yT(J)]; zq = [z(1:n,J);zT(J)];                %wet offsets
        
        Y     = -(zq-zT(J)); Y = flipud(Y); X = flipud(yq); Z = X+i*Y;
        s     = abs(Z);
        fi    = angle(Z);
        dfi   = diff(fi);
        h     = s(2:length(s)).*sin(dfi);
        dA    = 0.5*s(1:(length(s)-1)).*h(1:(length(s)-1));
        A(J)  = 2*sum(dA);
    end
end

q2     = size(x,2);  q1 = round(q2/2);  q3 = find(yT(q1:q2)<=0);
if isempty(q3); Lq=max(x(1,:)); else xtemp=x(1,q1:q2); Lq=min(xtemp(q3-1)); end
LBT    = [Lq 2*max(yT) Te];

dx     = diff(x(1,:));
dxx    = [0.5*dx(1) (0.5*dx(1:(length(dx)-1))+0.5*dx(2:length(dx))) 0.5*dx(length(dx))];
V      = A*dxx';
LCB    = (x(1,:)*(A.*dxx)')/V;
%LCB    = (x(1,:)*(A.*dxx)')/V - LBT(1)/2;

% [alfa] = Simpson(x(1,:));
% V      = A*alfa;
% LCB    = (x(1,:)*(A.*alfa')')/V - LBT(1)/2;

CB     = V/(LBT(1)*LBT(2)*LBT(3));

qq = find(yT>0);
figure(OF3); hold off; plot(x(1,qq),yT(qq),'b'); hold on; plot(x(1,qq),-yT(qq),'b'); axis equal; axis tight;
% figure(OF3); hold off; plot(x(1,qq),yT(qq)); hold on; plot(x(1,qq),-yT(qq)); axis equal; axis tight;
xlabel('x [m]');ylabel('y [m]'); title(['Waterline at T=' num2str(Te,3) ' m']);
%LCBc = LCB+LBT(1)/2;
figure(OF4); hold off; plot(x(1,:),A); hold on; plot([LCB LCB],[0 max(A)],':'); text(LCB,[max(A)/2],['LCB=' num2str(LCB,3) ' m']); axis tight;
xlabel('x [m]');ylabel('Section area [m^2]'); title(['Wet section areas for T=' num2str(Te,3) ' m']);

return;
% ------------------------------------------------------------------------------------------


% ----- Simpson ----------------------------------------------------------------------------
%funktion som integrerar funktionsvŠrdena i y över x.
%Kräver minst 3 funktionsvärden.
function [alfa]=Simpson(x);
global OF1 OF2 OF3 OF4;
s=size(x,2);
alfa=zeros(s,1);
for i=1:2:s-2
    A=zeros(3,3);b=zeros(3,1);AlfaTemp=zeros(3,1);
    A(1,:)=ones(1,3);
    A(2,:)=[x(i) x(i+1) x(i+2)];
    A(3,:)=[x(i)^2 x(i+1)^2 x(i+2)^2];
    b(1,1)=x(i+2)-x(i);
    b(2,1)=(x(i+2)^2-x(i)^2)/2;
    b(3,1)=(x(i+2)^3-x(i)^3)/3;
    AlfaTemp=A\b;
    alfa(i:i+2,1)=	alfa(i:i+2,1)+AlfaTemp;
end
alfa=abs(alfa);
return;
% ------------------------------------------------------------------------------------------


% ----- plotta spantruta -------------------------------------------------------------------
function []=PlotBodyPlan(x,y,z,np,LBT,Typ);
global OF1 OF2 OF3 OF4;
for J=1:floor(size(x,2)/2)
    Q = 1:np(J);  plot(-y(Q,J),z(Q,J),Typ); hold on;
end
for J=floor(size(x,2)/2):size(x,2)
    Q = 1:np(J);  plot(y(Q,J),z(Q,J),Typ);
end
axis equal; axis tight; xlabel('y [m]');ylabel('z [m]');
return
% ------------------------------------------------------------------------------------------


% ----- plotta -----------------------------------------------------------------------------
function []=Plotta(x,y,z,np);
global OF1 OF2 OF3 OF4;
figure(OF1); subplot(3,1,2); hold off;
for J=1:size(x,2)
    Q = 1:np(J);
    plot3(x(Q,J),y(Q,J),z(Q,J),'k.-'); hold on;
    plot3(x(Q,J),-y(Q,J),z(Q,J),'k.-');
end
axis equal; axis tight; xlabel('x [m]');ylabel('y [m]');zlabel('z [m]'); view([50 25]); %view([120 20]);
return
% ------------------------------------------------------------------------------------------


% ----- ReadBritfair ----------------------------------------------------------------------
function [x,y,z,np,K,namn]=ReadBritfair;
global OF1 OF2 OF3 OF4;

%cd 'C:\Anders\Proffs\Software\Tribon\Skrov\'
[fname,path]=uigetfile('*.*','Choose parent britfair file :');
%cd 'C:\Anders\mellan';

fid=fopen([path fname],'r');
namn = fgetl(fid); slaskrad = fgetl(fid);
[SecHead,count]=fscanf(fid,'%f',3) ;

J = 0;
while SecHead(1)>0
    if SecHead(3)>-999
        J      = J+1; I = 1;
        K(I,J) = 0;
        np(J)  = SecHead(1);
        Q      = 1:np(J);
        xk     = SecHead(3);
    else
        K(I,J) = 1;
        np(J)  = np(J)+SecHead(1)-1;
        Q      = I:(I+SecHead(1)-1);
        xk     = x(1,J);
    end
    for I = Q
        [yz,count]=fscanf(fid,'%f',2) ;
        x(I,J) = xk;  y(I,J) = yz(1);  z(I,J) = yz(2);
    end
    [Slask,count]=fscanf(fid,'%f',1) ;
    if Slask~=0
        [Slask,count]=fscanf(fid,'%f',2) ;
    end
    [SecHead,count]=fscanf(fid,'%f',3) ;
end

fclose(fid);

return;
% ------------------------------------------------------------------------------------------


% ----- WriteBritfair ----------------------------------------------------------------------
function []=WriteBritfair(x,y,z,np,K,HP,namn);
global OF1 OF2 OF3 OF4;

%NyttNamn=[namn 'QL.bri'];
%NyttNamn=[namn 'MOD_L' num2str(HP(1),3) '_B' num2str(HP(3),3) '_T' num2str(HP(5),3) '_CB' num2str((HP(11)),2) '.bri'];

[name,path]=uiputfile(['AAAnewHull'],'Save new hull geometry in britfair format :');
% [fname,path]=uiputfile([namn '_QL.bri'],'Save new hull geometry in britfair format :');

fname = [name '.bri'];

fid=fopen([path fname],'wt','ieee-le');

fprintf(fid,'%s\n',[fname '_QL']);
fprintf(fid,'%s\n','1');

for J=1:size(x,2)
    n1 = find(K(:,J));
    if isempty(n1);
        fprintf(fid,'%s\n',num2str([np(J) x(1,J) x(1,J)]));
        for I=1:np(J)
            fprintf(fid,'%s\n',num2str([y(I,J) z(I,J)],5));
        end
        fprintf(fid,'%s\n','0');
    else
        n2=diff(n1);
        n3=[1;n1;np(J)];
        for Q=1:(length(n1)+1)
            if Q==1; SecHead=[num2str(n3(Q+1)-n3(Q)+1) '   ' num2str(x(1,J)) '   ' num2str(x(1,J))];
            else SecHead=[num2str(n3(Q+1)-n3(Q)+1) '   ' num2str(x(1,J))   '   -999']; end;
            fprintf(fid,'%s\n',num2str(SecHead,3));
            for I=n3(Q):n3(Q+1)
                fprintf(fid,'%s\n',num2str([y(I,J) z(I,J)],5));
            end
            fprintf(fid,'%s\n','0');
        end
    end
end

fprintf(fid,'%s\n',num2str([0 0 0]));

fclose(fid);

WriteStripGeometry(x,y,z,np,HP,name);

return;
% ------------------------------------------------------------------------------------------


% ----- WriteStripGeometry ------------------------------------------------
function []=WriteStripGeometry(x,y,z,np,HP,namn)

AddZeros=1;

% --- reduce number of offsets -------
if max(np)>39
    x1 = zeros(39,length(np));
    y1 = zeros(39,length(np));
    z1 = zeros(39,length(np));
    
    for I=1:length(np)
        zmax = max(z(:,I));
        a = find(z(:,I)>=zmax);
        step = ceil(np(I)/38);
        x0 = x([1:step:min(a) max(a)],I);
        y0 = y([1:step:min(a) max(a)],I);
        z0 = z([1:step:min(a) max(a)],I);
        np1(I) = length(x0');
        x1(1:np1(I),I) = x0;
        y1(1:np1(I),I) = y0;
        z1(1:np1(I),I) = z0;
    end
    x=x1; y=y1; z=z1; np=np1;
end
% --- end reduce number of offsets ---

%NyttNamn=[namn 'MOD_StripGeometry.txt'];
fid=fopen([namn '_StripGeometry.txt'],'wt','ieee-le');

fprintf(fid,'%s\n',['*' [namn '_StripGeometry']]);
fprintf(fid,'%s\n',num2str(HP(1)));      % Lpp
fprintf(fid,'%s\n','0');
fprintf(fid,'%s\n','0');
fprintf(fid,'%s\n',num2str(size(x,2)));
fprintf(fid,'%s\n','0');
fprintf(fid,'%s\n','false');

for J=1:size(x,2)
    fprintf(fid,'%s\n','true');
    fprintf(fid,'%s\n','false');
    fprintf(fid,'%s\n',num2str(J));
    fprintf(fid,'%s\n',num2str(x(1,J)));
    fprintf(fid,'%s\n',num2str(np(J)+AddZeros));
    for I=1:np(J)
        fprintf(fid,'%s\n',[num2str(y(I,J)) ' ' num2str(z(I,J))]);
    end
    if AddZeros==1; fprintf(fid,'%s\n',[num2str(0) ' ' num2str(z(I,J))]);end;
end
fprintf(fid,'%s\n',num2str(0));

fclose(fid);
% ------------------------------------------------------------------------------------------
