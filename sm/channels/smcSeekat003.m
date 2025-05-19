function voltage = smcSeekat003(ic, voltage)


    %Driver for OpenDAC Seekat Serial number 003. (black one with white octopus)
    %Last update: HOHC 8-28-2014

 %   global smdata;
    global a;
    %strchan = smdata.inst(ic(1)).channels(ic(2),:);
    

switch ic(3)
    case 0  %read (get the DAC voltage)
        
        switch ic(2)    %select the channel and set communication bytes
            case 1
                n1 = 16+128;
                n2=0;
                m1=1;
                m2=0;
            case 2
                n1 = 17+128;
                n2=0;
                m1=1;
                m2=0;
            case 3
                n1 = 18+128;
                n2=0;
                m1=1;
                m2=0;
            case 4
                n1 = 19+128;
                n2=0;
                m1=1;
                m2=0;
            case 5
                n1 = 0;
                n2=16+128;
                m1=0;
                m2=1;
            case 6
                n1 = 0;
                n2=17+128;
                m1=0;
                m2=1;
            case 7
                n1 = 0;
                n2=18+128;
                m1=0;
                m2=1;
            case 8
                n1 = 0;
                n2=19+128;
                m1=0;
                m2=1;
            otherwise
                disp('INVALID CHANNEL')
        end
        
            %read the voltage
            pause(.02);
            fwrite(a,[255,254,253,n1,0,0,n2,0,0]);
            pause(.02);
            fwrite(a,[255,254,253,n1,0,0,n2,0,0]);
            pause(.02);
            while a.BytesAvailable
                fscanf(a,'%e'); % clear the buffer
            end
            fwrite(a,[255,254,253,0,0,0,0,0,0]);
            pause(.01);

            bdata=zeros([1,6]);
            for i=0:5;
              i=i+1;
              r=fscanf(a,'%e');
              bdata(i)=r;
            end
            bdata2=max(bdata(2)*2^8+bdata(3),bdata(5)*2^8+bdata(6));

            if bdata2 < 2^15
                %disp(10*bdata2/(2^15-1))
                %bdata3=sprintf('%20f',10.0*bdata2/(2^15-1));
                bdata3=10.0*bdata2/(2^15-1);
            else
                %bdata3=sprintf('%20f',-10.0*(2^16-bdata2)/2^15);
                bdata3=-10.0*(2^16-bdata2)/2^15;
                %disp(-10*(2^16-bdata2)/2^15)
            end
            voltage = bdata3;
        
        
    case 1  %write  (set the DAC voltage)

    switch ic(2)    %select the channel and set the communication bytes
        case 1
            n1 = 16;
            n2=0;
            m1=1;
            m2=0;
        case 2
            n1 = 17;
            n2=0;
            m1=1;
            m2=0;
        case 3
            n1 = 18;
            n2=0;
            m1=1;
            m2=0;
        case 4
            n1 = 19;
            n2=0;
            m1=1;
            m2=0;
        case 5
            n1 = 0;
            n2=16;
            m1=0;
            m2=1;
        case 6
            n1 = 0;
            n2=17;
            m1=0;
            m2=1;
        case 7
            n1 = 0;
            n2=18;
            m1=0;
            m2=1;
        case 8
            n1 = 0;
            n2=19;
            m1=0;
            m2=1;
        otherwise
            disp('INVALID CHANNEL')
    
    end
        
     if voltage > 10
         voltage = 10.0;
     elseif voltage < -10
         voltage = -10.0;
     end
    
        if voltage >= -20/(2^17)
            dec16 = round((2^15-1)*voltage/10); %Decimal equivalent of 16 bit data 
        else
            dec16 = round(2^16 - max(abs(voltage)/10 * 2^15,1)); %Decimal equivalent of 16 bit data 
        end

        bin16 = de2bi(dec16,16,2,'left-msb'); %16 bit binary
        
        d1=bi2de(fliplr(bin16(1:8))); %first 8 bits
        d2=bi2de(fliplr(bin16(9:16))); %second 8 bits
        %disp([255,254,253,n1,d1*m1,d2*m1,n2,d1*m2,d2*m2]);
        pause(.005);
        fwrite(a,[255,254,253,n1,d1*m1,d2*m1,n2,d1*m2,d2*m2]);
            while a.BytesAvailable
                fscanf(a,'%e');
            end
    
end

    
end

