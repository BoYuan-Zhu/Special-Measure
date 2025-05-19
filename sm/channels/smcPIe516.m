function val = smcPIe516(ic, val, rate)
%Channels
% Enter val in microns for position
%1 - 'X' Voltage(commanded) output for channel A
%2 - 'Y' Voltage(commanded) output for channel B
%3 - 'Xpos' Position output for channel A
%4 - 'Ypos' Position output for channel B
%5 - 'XmaxV' Upper voltage limit for channel A
%6 - 'YmaxV' Upper voltage limit for channel B
%7 - 'XminV' Lower voltage limit for channel A
%8 - 'YminV' Lower voltage limit for channel B
%9 - 'XactV' Voltage(actual) output for channel A
%10 - 'YactV' Voltage(actual) output for channel B
%11 - 'XSVO' Turns servor for channel A on/off
%12 - 'YSVO' Turns servor for channel B on/off
%13 - 'Xrel' Moves position by _ relative to last position in channel A
%14 - 'Yrel' Moves position by _ relative to last position in channel B
%15 - 'XPOL+' ADD WAVE in channel A 
%16 - 'YPOL+' ADD WAVE in channel B 
%17 - 'XPOL' Replace WAVE in channel A 
%18 - 'YPOL' Replace WAVE in channel B 
%19 - 'XCFG' Specifies additional parameters for waves in channel A
%20 - 'YCFG' Specifies additional parameters for waves in channel B
%21 - 'XWGO' Starts or stops wave in channel A
%22 - 'YWGO' Starts of stops wave in channel B
%23 - 'DEL' Delays

%Driver for Physik Instrumente E-516 Piezo Controller

global smdata;
inst = smdata.inst(ic(1)).data.inst;

switch ic(2) % Channels 

    case 1 %X
        switch ic(3) %get/set
            case 0 %get
                val = query(inst, sprintf('SVA? A'), '%s\n', '%f');
            case 1 %set
                fprintf(inst, sprintf('SVA A %f', val));
            otherwise
                error('Piezo Controller driver: Operation not supported');
        end
    case 2 %Y
        switch ic(3) %get/set
            case 0 %get
                val = query(inst, sprintf('SVA? B'), '%s\n', '%f');
            case 1 %set
                fprintf(inst, sprintf('SVA B %f', val));
            otherwise
                error('Piezo Controller driver: Operation not supported');
        end
    case 3 %Xpos 
        switch ic(3) %get/set
            case 0 %get
                val = query(inst,sprintf('POS? A'), '%s\n', '%f');
            case 1 %set
                fprintf(inst,sprintf('MOV A %f', val));
            otherwise
                error('Piezo Controller driver: Operation not supported');
        end
    case 4 %Ypos
        switch ic(3) %get/set
            case 0 %get
                val = query(inst,sprintf('POS? B'), '%s\n', '%f');
            case 1 %set
                fprintf(inst,sprintf('ONL 1'));
                fprintf(inst,sprintf('MOV B %f', val));
                fprintf(inst,sprintf('ONL 0'));
            otherwise
                error('Piezo Controller driver: Operation not supported');
        end
    case 5 %XMaxV
        switch ic(3) %get/set
            case 0 %get
                val = query(inst,sprintf('VMA? A'), '%s\n', '%f');
            case 1 %set
                fprintf(inst,sprintf('VMA A %f', val));
            otherwise
                error('Piezo Controller driver: Operation not supported');
        end
    case 6 %YMaxV
        switch ic(3) %get/set
            case 0 %get
                val = query(inst,sprintf('VMA? B'), '%s\n', '%f');
            case 1 %set
                fprintf(inst,sprintf('VMA B%f', val));
            otherwise
                error('Piezo Controller driver: Operation not supported');
        end
    case 7 %XMinV
        switch ic(3) %get/set
            case 0 %get
                val = query(inst,sprintf('VMI? A'), '%s\n', '%f');
            case 1 %set
                fprintf(inst,sprintf('VMI A %f', val));
            otherwise
                error('Piezo Controller driver: Operation not supported');
        end
    case 8 %YMinV
        switch ic(3) %get/set
            case 0 %get
                val = query(inst,sprintf('VMI? B'), '%s\n', '%f');
            case 1 %set
                fprintf(inst,sprintf('VMI B %f', val));
            otherwise
                error('Piezo Controller driver: Operation not supported');
        end
    case 9 %XactV
        switch ic(3) %get/set
            case 0 %get
                val = query(inst,sprintf('VOL? A'), '%s\n', '%f');
            case 1 %set
                fprintf(inst,sprintf('SVA A %f', val));
            otherwise
                error('Piezo Controller driver: Operation not supported');
        end
    case 10 %YactV
        switch ic(3) %get/set
            case 0 %get
                val = query(inst,sprintf('VOL? B'), '%s\n', '%f');
            case 1 %set
                fprintf(inst,sprintf('SVA B %f', val));
            otherwise
                error('Piezo Controller driver: Operation not supported');
        end
    case 11 %XSVO
        switch ic(3) %get/set
            case 0 %get
                val = query(inst,sprintf('SVO A'), '%s\n', '%f');
            case 1 %set
                fprintf(inst,sprintf('SVO A %f', val));
            otherwise
                error('Piezo Controller driver: Operation not supported');
        end
     case 12 %YSVO
         switch ic(3) %get/set
             case 0 %get
                 val = query(inst,sprintf('SVO B'), '%s\n', '%f');
             case 1 %set
                 fprintf(inst,sprintf('SVO B %f', val));
             otherwise
                 error('Piezo Controller driver: Operation not supported');
         end
      case 13 %Xrel
          switch ic(3) %get/set
              case 0 %get
                  val = query(inst,sprintf('POS? A'), '%s\n', '%f');
              case 1 %set
                  fprintf(inst,sprintf('MVR A %f', val));
              otherwise
                  error('Piezo Controller driver: Operation not supported');
          end
       case 14 %Yrel
           switch ic(3) %get/set
               case 0 %get
                   fprintf(inst,sprintf('MVR B %f', val));
                   val = query(inst,sprintf('POS? B'), '%s\n', '%f');
               case 1 %set
                   fprintf(inst,sprintf('MVR B %f', val));
               otherwise
                   error('Piezo Controller driver: Operation not supported');
           end 
       case 15 %XPOL+
           switch ic(3) %get/set
               case 0 %get
                   val = query(inst,sprintf('GWD? A'), '%s\n', '%f');
               case 1 %set
                   fprintf(inst,sprintf('WAV A+ POL %f',val));
               otherwise
                   error('Piezo Controller driver: Operation not supported');
           end
       case 16 %YPOL+
           switch ic(3) %get/set
               case 0 %get
                   val = query(inst,sprintf('GWD? B'), '%s\n', '%f');
               case 1 %set
                   fprintf(inst,sprintf('WAV B+ POL %f',val));
               otherwise
                   error('Piezo Controller driver: Operation not supported');
           end
       case 17 %XPOL
           switch ic(3) %get/set
               case 0 %get
                   val = query(inst,sprintf('GWD? A'), '%s\n', '%f');
               case 1 %set
                   fprintf(inst,sprintf('WGO A0'));
                   fprintf(inst,sprintf('WAV A POL 3846 3846 0 %f 0',val));
                   fprintf(inst,sprintf('WAV A CFG 7692 1 0 5 2 10'));
                   fprintf(inst,sprintf('WGO A1'));
               otherwise
                   error('Piezo Controller driver: Operation not supported');
           end
       case 18 %YPOL
           switch ic(3) %get/set
               case 0 %get
                   val = query(inst,sprintf('GWD? B'), '%s\n', '%f');
               case 1 %set
                   fprintf(inst,sprintf('WAV A POL 3846 3846 0 %f 0',val));
               otherwise
                   error('Piezo Controller driver: Operation not supported');
           end
       case 19 %XCFG
           switch ic(3) %get/set
               case 0 %get
                   val = query(inst,sprintf('GWD? A'), '%s\n', '%f');
               case 1 %set
                   fprintf(inst,sprintf('WAV A CFG %f',val));
               otherwise
                   error('Piezo Controller driver: Operation not supported');
           end
       case 20 %YCFG
           switch ic(3) %get/set
               case 0 %get
                   val = query(inst,sprintf('GWD? B'), '%s\n', '%f');
               case 1 %set
                   fprintf(inst,sprintf('WAV B CFG 7692 1 0 %f 2 10',val));
               otherwise
                   error('Piezo Controller driver: Operation not supported');
           end
       case 21 %XWGO
           switch ic(3) %get/set
               case 0 %get
                   val = query(inst,sprintf('GWD? A'), '%s\n', '%f');
               case 1 %set
                   fprintf(inst,sprintf('MOV A0 B %f',val));
%                    fprintf(inst,sprintf('MVR B1'));
                   fprintf(inst,sprintf('WGO A1'));
               otherwise
                   error('Piezo Controller driver: Operation not supported');
           end
       case 22 %YWGO
           switch ic(3) %get/set
               case 0 %get
                   val = query(inst,sprintf('GWD? B'), '%s\n', '%f');
               case 1 %set
                   fprintf(inst,sprintf('WGO B %f',val));
               otherwise
                   error('Piezo Controller driver: Operation not supported');
           end
       case 23 %DEL
           switch ic(3) %get/set
               case 0 %get
                   val = query(inst,sprintf('GWD? B'), '%s\n', '%f');
               case 1 %set
                   fprintf(inst,sprintf('DEL %f',val));
               otherwise
                   error('Piezo Controller driver: Operation not supported');
           end
       case 24 %UNISCAN
%            - Determine starting point
%            - Determine Y moving loop
           switch ic(3) %get/set
               case 0 %get
                   val = query(inst,sprintf('GWD? B'), '%s\n', '%f');
               case 1 %set
                   xlen=2;
                   pts=200; 
                   time=.1; % Measure with K2700 NoBuff
                   fprintf(inst,sprintf('VEL A10 B10'));
                   fprintf(inst,sprintf('MOV A0 B5'));
                   fprintf(inst,sprintf('WGC A %f', pts));
                   fprintf(inst,sprintf('WGO A0'));
                   fprintf(inst,sprintf('WAV A POL 3846 3846 0 1 0'));
                   fprintf(inst,sprintf('WAV A POL 0 3846 0 0 0'));
                   fprintf(inst,sprintf('WAV A %f 1 0 1 %f %f', time/(0.000052*pts),xlen/pts,xlen));
%                    fprintf(inst,sprintf('WGO A1'));
%                    fprintf(inst,sprintf('DEL 1'));
%                    fprintf(inst,sprintf('MVR B %f',val));
%                    fprintf(inst,sprintf('DEL 100'));
               otherwise
                   error('Piezo Controller driver: Operation not supported');
           end
       case 25 %TEST
           switch ic(3) %get/set
               case 0 %get
                   val = query(inst,sprintf('GWD? B'), '%s\n', '%f');
               case 1 %set
                   fprintf(inst,sprintf('MVR A %f', val));
%                    fprintf(inst,sprintf('DEL 1'));
                   fprintf(inst,sprintf('MVR A %f', val));
               otherwise
                   error('Piezo Controller driver: Operation not supported');
           end
    otherwise
        error('Piezo Controller  driver: Nonvalid Channel specified');
end

end