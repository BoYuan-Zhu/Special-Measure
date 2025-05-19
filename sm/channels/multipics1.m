function image_data = multipics1(mode, EXPTIME, lambda);
global h_cam smdata;
x_size = pvcamgetvalue(h_cam, 'PARAM_SER_SIZE'); % obtain size of serial register 
y_size = pvcamgetvalue(h_cam, 'PARAM_PAR_SIZE'); % obtain size of parallel register 
pvcamsetvalue(h_cam, 'PARAM_SPDTAB_INDEX', 1); % set camera to max readout speed 
pvcamsetvalue(h_cam, 'PARAM_GAIN_INDEX', 2); % set camera to max gain 
%roi_struct = cell2struct({0, x_size-1, 1, 0, y_size - 1, 1}, {'s1', 's2', 'sbin', 'p1', 'p2', 'pbin'}, 2); 
roi_struct = cell2struct({0, x_size-1, 1, 132, 206, 1}, {'s1', 's2', 'sbin', 'p1', 'p2', 'pbin'}, 2); 

dat=pvcamacq(h_cam, 1, roi_struct, EXPTIME, 'timed');
dat=roiparse(dat, roi_struct);
lambda=1340-((lambda-532)*847./368.+225);
x=1:1340;
%x=1341-x
noise=sum(dat(:,200))/33-.5;
x=532+(1340-x-225)*368./847.;
switch mode
    case 0
        image_data=sum(sum(dat));
    case 1
        image_data=sum(dat(:,round(lambda)))/400-noise;
    case 2
        dat=avecol(dat);
                
        image_data=sum(dat(round(lambda(2)):round(lambda(1))))/(lambda(1)-lambda(2))-noise;
    
    case 3
        image_data=avecol(dat)-noise;
       %image_data=image_data';
    case 4
        image_data=avecol(dat)-noise;
        figure
        plot(x,image_data);
        xlim([430 950]);
end

    
