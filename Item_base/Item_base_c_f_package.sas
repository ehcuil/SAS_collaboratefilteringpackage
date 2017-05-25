/*	Item-base collaborative filtering Package - by Che	*/
/*	CAUTION: Use only "product_" as prefix of each product that would be dealt in modelling phase	*/
/*	For example: when dealing with 42 products, set product_1 as first product and product_2 as second product, et cetera	*/
/*	Value across all product variable should be either 0 ir 1, indicating not done or done	*/
/*	Other variable will be abandoned during the phase but retained in the result	*/
/*	It is strongly suggested to set the number of products under 50 as of acceptable performance	*/

/*	Updates quotes	*/
/*	2017.05.25 updates	*/ 
/*	1.	change "outname" to "outratings"	*/
/*	2.	the customer order does not change overtime, however it is suggested to keep at least*/
/*	1 observation indicator in "outratings" so that you won't get lost on final output	*/	
/*	3.	I accidentally made every loop pointer either i or j... now they are i j k l m n ...	*/
/*	4.	"outname" now is for the output of final recommendation table	*/



%MACRO C_FILTERING(&libname1=, in_data1=, outlib=, outratings=, outvars=, outname=);

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
			
			%DO k = 1 %TO &num_products.;
				%DO l = 1 %TO &num_products.;
					IF &k. = &l. THEN
						result_&k._&l. = 0;
					ELSE
						result_&k._&l. = total_&k._&l. / (SQRT(total_&k.) * SQRT(total_&l.));
				%END;
			%END;
	RUN;
	
	
	PROC SQL NOPRINT;
		CREATE TABLE _3 AS
			SELECT * FROM &libname..&in_data1. CROSS JOIN _2;
	QUIT;
	
	
	DATA &outlib..&outratings.(KEEP=&outvars. product_result_sum_:);
		SET _3;
			
			%DO m = 1 %TO &num_products.;
				%DO n = 1 %TO &num_products.;
					product_result_&m._&n. = product_&n. * result_&m._&n.;
				%END;
				product_result_sum_&m. = sum(of product_result_&m._:);
			%END;
	RUN;
	
	PROC DATASET LIBRARY=work MTYPE=DATA;
		DELETE _1 _2 _3;
	RUN;
	

	DATA &outlib..&outname.(DROP=product_result_sum_:);
		LENGTH p1-p5 8. np1-np5 $50.;									/* Modify by yourself if your product */
		SET &outlib..&outratings;											/* name exceed 50 characters */
			%DO o = 1 %TO &num_products.;
				IF product_result_sum_&o. > p5 THEN DO;
					p5 = product_result_sum_&o.;
					np5 = "product_&o.";
					IF product_result_sum_&o. > p4 THEN DO;
						p5 = p4;
						np5 = np4;
						p4 = product_result_sum_&o.;
						np4 = "product_&o.";
						IF product_result_sum_&o. > p3 THEN DO;
							p4 = p3;
							np4 = np3;
							p3 = product_result_sum_&o.;
							np3 = "product_&o.";
							IF product_result_sum_&o. > p2 THEN DO;
								p3 = p2;
								np3 = np2;
								p2 = product_result_sum_&o.;
								np2 = "product_&o.";
								IF product_result_sum_&o. > p1 THEN DO;
									p2 = p1;
									np2 = np1;
									p1 = product_result_sum_&o.;
									np1 = "product_&o.";
								END;
							END;
						END;
					END;
				END;
			%END;
	RUN;


%MEND;

%C_FILTERING(libname1=, in_data1=, outlib=, outratings=, outvars=, outname=);