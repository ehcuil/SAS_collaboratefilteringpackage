/*	Item-base collaborative filtering Package - by Che	*/
/*	CAUTION: Use only "product_" as prefix of each product that would be dealt in modelling phase	*/
/*	For example: when dealing with 42 products, set product_1 as first product and product_2 as second product, et cetera	*/
/*	Value across all product variable should be either 0 ir 1, indicating not done or done	*/
/*	Other variable will be abandoned during the phase but retained in the result	*/
/*	It is strongly suggested to set the number of products under 50 as of acceptable performance	*/

%MACRO C_FILTERING(&libname1=, in_data1=, outlib=, outname=, outvars=);

	PROC SQL NOPRINT;
		SELECT COUNT(DISTINCT NAME) INTO :num_products FROM sashelp.vcolumn
			WHERE libname = "%upcase(&libname1.)" and memname = "%upcase(&in_data1.)" and name like 'product_%';
	QUIT;
	
	
	DATA _1;
		SET &libname1..&in_data1.(KEEP=product_: END=eof);
		
			%DO i = 1 %TO &num_products.;
				total_&i. + product_&i.;
				%DO j = 1 %TO &num_products.;
					product_&i._&j. = product_&i. * product_&j.;
					total_&i._&j. + product_&i._&j.;
				%END;
			%END;
			
			IF eof THEN OUTPUT;
			
	RUN;
	
	
	DATA _2(KEEP=result_:);
		SET _1;
			
			%DO i = 1 %TO &num_products.;
				%DO j = 1 %TO &num_products.;
					IF &i. = &j. THEN
						result_&i._&j. = 0;
					ELSE
						result_&i._&j. = total_&i._&j. / (SQRT(total_&i.) * SQRT(total_&j.));
				%END;
			%END;
	RUN;
	
	
	PROC SQL NOPRINT;
		CREATE TABLE _3 AS
			SELECT * FROM &libname..&in_data1. CROSS JOIN _2;
	QUIT;
	
	
	DATA &outlib..&outname.(KEEP=&outvars. product_result_sum_:);
		SET _3;
			
			%DO i = 1 %TO &num_products.;
				%DO j = 1 %TO &num_products.;
					product_result_&i._&j. = product_&j. * result_&i._&j.;
				%END;
				product_result_sum_&i. = sum(of product_result_&i._:);
			%END;
	RUN;
	
	PROC DATASET LIBRARY=work MTYPE=DATA;
		DELETE _1 _2 _3;
	RUN;
	
%MEND;

%C_FILTERING(libname1=, in_data1=, outlib=, outname=, outvars=);