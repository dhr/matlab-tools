function inside = ptPtInRect(pos, rect)

inside = pos(1) >= rect(1) && pos(2) >= rect(2) && pos(1) < rect(3) && pos(2) < rect(4);