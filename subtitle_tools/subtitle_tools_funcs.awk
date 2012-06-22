
# ###########################################################################
# shared functions
# ###########################################################################

function f_chr(in_nr)
{
  if(in_nr<0)
    return("");
  else
    return(sprintf("%c", int(in_nr + 0)));      # return char using sprintf()
}

function f_ord(in_chr)
{
  if (f_ord_arr[-1] != 256)
  {                                             # test whether chr-arr is ready
    f_ord_arr[-1] = 256;
    for(f_ord_i=0;f_ord_i<f_ord_arr[-1];f_ord_i++)             # create chr-arr
    {
      f_ord_arr[sprintf("%c",f_ord_i)] = f_ord_i;
    }
  }
  if(length(in_chr)>0)
    return(f_ord_arr[sprintf("%c",substr(in_chr,1,1))]);# return position number
  else
    return(-1);                                 # error code
}


function to_float( in_h, in_m, in_s )
{
  return( ((in_h+0)*60*60)+((in_m+0)*60)+(in_s+0.0) );
}

function f_srtime2sec ( in_srt )
{
  sarr[-1] = split(in_srt, sarr, /[,:]/);
  return(to_float( (0 + sarr[1]), (0 + sarr[2]), ((0 + sarr[3]) + (0.001 * sarr[4])) ));
}


function f_sec2srtime ( in_sec )
{
  return(sprintf("%02d:%02d:%02d,%03d", int(in_sec/(60*60)), 
                                        int(in_sec/60)%60, 
                                        int(in_sec)%60, 
                                        int(1000*(in_sec - int(in_sec))) ));
}

# abs ( in_nr )
# absolute value
function abs( in_nr )
{
  if (in_nr < 0)
    return(0-in_nr);
  else
    return(0+in_nr);

}

# find_ts ( subtitle-number )
# finds the subtitle's starting timestamp
function find_ts ( in_sbttl_nr )
{
  tmp_ts=0
  for (i_ts=0;i_ts<srtarr[-1]; i_ts++)
  {
    if( srtarr[i_ts,0] == in_sbttl_nr )
    {
      tmp_ts=srtarr[i_ts,1];
      break;
    }
  }
  
  return(tmp_ts);
}

# trim_spaces ( in_str )
# removehead and tail blank spaces
function trim_spaces( in_str )
{
  tmp_str=in_str;
  
  # head trimming
  while ( 1 )
  {
    if (f_ord(substr(tmp_str,1,1))<=32)
      tmp_str=substr(tmp_str,2);
    else
      break;
   
   if(length(tmp_str)==0)
     break;
  }
    
  
  # tail trimming
  while ( 1 )
  {
    if (f_ord(substr(tmp_str,length(tmp_str),1))<=32)
      tmp_str=substr(tmp_str,1,length(tmp_str)-1);
    else
      break;
   
   if(length(tmp_str)==0)
     break;
  }
    

  return(tmp_str);
}


# eof
