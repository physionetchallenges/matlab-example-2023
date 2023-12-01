function y = calculate_checksum(x)
    n = length(x);
    y = 0; % Double precision, but better to use an integer; not optimal.
    for i = 1:n
        y = mod(y + x(i) + 2^15, 2^16) - 2^15; % Wrapping may not be needed for each partial sum, but taking advantage of the larger range to write simpler code; not optimal.
    end
end