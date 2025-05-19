function result = avs47Decode( data )
% Translate 48-bit output to AVS-47 reading

result.overrange = data(6);
pol = data(7);
d4 = data(8);
d3 = bi2de(data(9:12), 'left-msb');
d2 = bi2de(data(13:16), 'left-msb');
d1 = bi2de(data(17:20), 'left-msb');
d0 = bi2de(data(21:24), 'left-msb');

rdg = 10000*d4 + 1000*d3 + 100*d2 + 10*d1 + d0;

if pol==0
    rdg = -1*rdg;
end

result.input = bi2de(data(27:28), 'left-msb');
result.channel = bi2de(data(29:31), 'left-msb');
result.display = bi2de(data(32:34), 'left-msb');
result.excitation = bi2de(data(35:37), 'left-msb');
result.range = bi2de(data(38:40), 'left-msb');
result.adc = rdg;
result.res = rdg * 10^(result.range - 5);

end

