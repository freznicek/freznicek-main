
# begin initial rule
# ###########################################################################
BEGIN{
  
  mode=0
  str_arrow="-->"
  # internal array
  # srtarr[-1]      counter
  # srtarr[.,0]     subtitle's number / index
  # srtarr[.,1]     subtitle's begin timestamp
  # srtarr[.,2]     subtitle's end timestamp
  # srtarr[.,3]     subtitle's text
  srtarr[-1]=0;
  
  # input variables
  # a] first approach
  #   mod_offset, mod_scale
  # b] second approach
  #   mod_begin, mod_end
  # c] third approach
  #   mod_ts_a_old & mod_ts_a_new
  #   mod_ts_b_old & mod_ts_a_new
  
  if(mod_offset == "")
    mod_offset=0.0;
  if(mod_scale == "")
    mod_scale=1.000;
  
  if(mod_begin == "")
    mod_begin=-1;
  if(mod_end == "")
    mod_end=-1;
  
  if(mod_ts_a_old == "")
    mod_ts_a_old=-1;
  if(mod_ts_a_new == "")
    mod_ts_a_new=-1;
  if(mod_ts_b_old == "")
    mod_ts_b_old=-1;
  if(mod_ts_b_new == "")
    mod_ts_b_new=-1;
  
}


# @ line rule
# ###########################################################################
{
  
  in_str=trim_spaces($0);
  in_str_arr[-1]=split(in_str, in_str_arr);
  
  # index detected
  if ( (in_str_arr[-1]==1) && (mode == 0) && (in_str_arr[1] ~ /[0-9]+/) )
  {
    # subtitle nr detected
    srtarr[srtarr[-1],0]=in_str_arr[1];
    mode=1;
  }
  
  # index detected
  if ( (mode == 1) && (in_str_arr[2] == str_arrow ) )
  {
    # subtitle nr detected
    srtarr[srtarr[-1],1]=in_str_arr[1];
    srtarr[srtarr[-1],2]=in_str_arr[3];
    mode=2;
  }
  
  if( (mode==2) && (in_str_arr[2] != str_arrow ) )
  {
    if (in_str_arr[-1]==0)
    {
      mode = 0;
      srtarr[-1]++;
    }
    else
    {
      if(srtarr[srtarr[-1],3] == "")
        srtarr[srtarr[-1],3] = in_str;
      else
        srtarr[srtarr[-1],3] = sprintf("%s\n%s", srtarr[srtarr[-1],3], in_str);
    }
  }
}

# end final rule
# ###########################################################################
END{
  
  # move counter of subtitles if needed (no \n at the end)
  if( (srtarr[srtarr[-1]+1,3] != "") && (srtarr[srtarr[-1]+1,0] != "") )
    srtarr[-1]++;
  
  # original subtitle stream - evaluation of timestamps (start, stop, duration)
  ori_begin = f_srtime2sec(srtarr[0,1]);
  ori_end = f_srtime2sec(srtarr[srtarr[-1]-1,2]);
  ori_length = 0.0 + ori_end - ori_begin;
  
  # real offset
  roffset = ori_begin + mod_offset;
  
  # detect input mode, trying method b]
  if ( (mod_begin != -1) && (mod_end != -1) )
  {
    # second approach begin + end
    mod_offset = 0.0 + mod_begin - ori_begin;
    mod_scale = (0.0 + mod_end - mod_begin) / ori_length;
    roffset = mod_begin;
  }
  
  # detect input mode, trying method c]
  if ( (mod_ts_a_old != -1) && (mod_ts_a_new != -1) && (mod_ts_b_old != -1) && (mod_ts_b_new != -1) )
  {
    mod_ts_a_old = trim_spaces(mod_ts_a_old);
    mod_ts_a_new = trim_spaces(mod_ts_a_new);
    mod_ts_b_old = trim_spaces(mod_ts_b_old);
    mod_ts_b_new = trim_spaces(mod_ts_b_new);
    
    if ( mod_ts_a_old ~ /^[0-9]+\.[0-9]+$/ )
      mod_ts_a_old = mod_ts_a_old + 0.0;
    else
      mod_ts_a_old = f_srtime2sec(find_ts(mod_ts_a_old));
    mod_ts_a_new = mod_ts_a_new + 0.0;
    
    if ( mod_ts_b_old ~ /^[0-9]+\.[0-9]+$/ )
      mod_ts_b_old = mod_ts_b_old + 0.0;
    else
      mod_ts_b_old = f_srtime2sec(find_ts(mod_ts_b_old));
    mod_ts_b_new = mod_ts_b_new + 0.0;
  
  
    # swap a and b ts if needed
    if ( (mod_ts_a_old > mod_ts_b_old) && (mod_ts_a_new > mod_ts_b_new) )
    {
      # swap needed
      tmp=mod_ts_a_old;
      mod_ts_a_old=mod_ts_b_old;
      mod_ts_b_old=tmp;
      
      tmp=mod_ts_a_new;
      mod_ts_a_new=mod_ts_b_new;
      mod_ts_b_new=tmp;
    }
    
    if( debug == 1 )
      printf("DEBUG>mod_ts_a:%g->%g,mod_ts_b:%g->%g\n", mod_ts_a_old,
             mod_ts_a_new, mod_ts_b_old, mod_ts_b_new) >> "/dev/stderr"
    
    # assign scale and offset
    # new length
    mod_length = (mod_ts_b_new-mod_ts_a_new)*(ori_length/(mod_ts_b_old-mod_ts_a_old));
    # scale = L' / L = (Lm'*(L/Lm)) / L
    mod_scale = mod_length / ori_length;
    
    # relative distance from start (original path)
    ori_percentage=(mod_ts_a_old-ori_begin)/ori_length
    
    # offset
    mod_begin = mod_ts_a_new - (ori_percentage * mod_length);
    roffset = mod_begin;
  }
  
  # print settings to stderr
  if( 1 )
  {
    printf("offset:%g; scale:%g; begin:%g->%g; end:%g->%g; length:%g\n", 
           mod_offset, mod_scale, ori_begin, mod_begin, ori_end, mod_end,
           ori_length) >> "/dev/stderr"
  }
  
  if( debug == 1 )
  {
    printf("DEBUG>%g->%g,%g->%g (%g)\n", ori_begin, mod_begin, ori_end, mod_end,
                                         ori_length) >> "/dev/stderr"
    printf("DEBUG>off:%g,scale:%g\n", mod_offset, mod_scale) >> "/dev/stderr"
    for (i=0;i<srtarr[-1];i++)
      printf("DEBUG>strarr[%d,0|1|2|3]=%s|%g|%g|%s\n", i, srtarr[i,0], 
             srtarr[i,1], srtarr[i,2], srtarr[i,3]) >> "/dev/stderr";
  }
  
  for(i=0;i<srtarr[-1];i++)
  {
    sts=((f_srtime2sec(srtarr[i,1])-ori_begin) * mod_scale) + roffset;
    ets=((f_srtime2sec(srtarr[i,2])-ori_begin) * mod_scale) + roffset;
    
    if( debug == 1 )
    {
      printf("%s\n%s %s %s (%s|%s)\n%s\n\n", srtarr[i,0], 
                                             srtarr[i,1], str_arrow, 
                                             srtarr[i,2], f_sec2srtime(sts),
                                             f_sec2srtime(ets), srtarr[i,3]);
    }
    else
    {
      printf("%s\n%s %s %s\n%s\n\n", srtarr[i,0], f_sec2srtime(sts),
                                     str_arrow , f_sec2srtime(ets),
                                     srtarr[i,3]);
    }
  }
}



# ###########################################################################
# eof
# ###########################################################################
