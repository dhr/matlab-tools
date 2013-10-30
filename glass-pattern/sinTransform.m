function f = sinTransform(amp, wavelength, phase, dist)    
    f = @doTransform;

    function newPs = doTransform(ps)
       xs = ps(:,1);
       ys = ps(:,2);
       
       freq = 2*pi/wavelength;
       dxdys = amp*freq*cos(freq*ys + phase);
       
       newYs = ys + dist./sqrt(1 + dxdys.^2);
       newXs = xs + amp*(sin(freq*newYs + phase) - sin(freq*ys + phase));
       
       newPs = [newXs newYs];
    end
end

