function [pts1]=input_handler(col_nob,pathname1,filename1);


if pathname1~=0 
   fil2=[pathname1,filename1];
   fid=fopen(fil2,'r');
   h = waitbar(0,'Veuillez patienter...');
   format bank;
   %fid = fopen('test1.txt');
   a = fscanf(fid,'%g %g',[3 inf]);   
   pts1=a';
   fclose(fid);
   close(h);
end