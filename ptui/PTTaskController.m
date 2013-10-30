classdef PTTaskController < handle
  properties
    UILoop
  end
  
  methods (Abstract)
    detach(obj);
  end
end