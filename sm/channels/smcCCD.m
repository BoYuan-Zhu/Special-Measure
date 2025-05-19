function val = smcCCD(ic, val, rate)

global smdata lambda_start lambda_center lambda_stop camera_int;
switch ic(2) % channel
    case 1  %acquire integrated intensity
        val=multipics1(0, camera_int, 500);
    case 2  %acquire single pixel
        val=multipics1(1, camera_int, lambda_center);
    
    case 3  %acquire band-integrated intensity
        val=multipics1(2, camera_int, [lambda_start, lambda_stop]);
    case 4  %acquire complete spectrum
        switch ic(3)
            case 0
        val=multipics1(3, camera_int, 500);
        val(1:30) = median(val);
            case 1
               % fprintf('write to the CCD please \n');
        end
    case 5
      switch ic(3) %get (0) or set (1) %set start wavelength for band integration
          case 0
          val = lambda_start;
        
          case 1
          lambda_start = val;
      end
   case 6   %set wavelength for single pixel acquisition
      switch ic(3) %get (0) or set (1) 
          case 0
          val = lambda_center;
        
          case 1
          lambda_center = val;
      end
   case 7   %set end wavelength for band integration
      switch ic(3) %get (0) or set (1) 
          case 0
          val = lambda_stop;
        
          case 1
          lambda_stop = val;
      end
   
  case 8    %set CCD integration time
      switch ic(3) %get (0) or set (1) 
          case 0
          val = camera_int;
        
          case 1
          camera_int = val;
      end
  case 9
       val = 0;
end