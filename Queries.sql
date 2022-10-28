SELECT * FROM CONTABILI WHERE SALARIU>4000 AND VENIT_PE_TRANZACTIE IS NULL;

SELECT DISTINCT A.ID_CONTABIL, A.NUME, A.PRENUME,TO_CHAR(A.DATA_ANGAJARII, 'YYYY.MM.DD') DATA_ANGAJARII
FROM CONTABILI A JOIN TRANZACTII B
ON A.ID_CONTABIL=B.ID_CONTABIL
WHERE TO_CHAR(A.DATA_ANGAJARII, 'YYYY.MM')<2021.06
ORDER BY A.ID_CONTABIL;


SELECT A.ID_CONTABIL, A.NUME, A.PRENUME, COUNT(B.ID_TRANZACTIE) TRANZACTII_INREGISTRATE
FROM CONTABILI A LEFT JOIN TRANZACTII B
ON A.ID_CONTABIL=B.ID_CONTABIL
GROUP BY A.ID_CONTABIL, A.NUME, A.PRENUME
HAVING COUNT(B.ID_TRANZACTIE)>0
ORDER BY COUNT(B.ID_TRANZACTIE) DESC;


SELECT A.SIMBOL, A.NUME, COUNT(B.ID_TRANZACTIE) NR_TRANZACTII
FROM PLAN_CONTURI A LEFT JOIN TRANZACTII B
ON A.SIMBOL=B.CONT_DEBIT OR A.SIMBOL=B.CONT_CREDIT
WHERE (A.SIMBOL BETWEEN 600 AND 699) OR (A.SIMBOL BETWEEN 6000 AND 6999)
GROUP BY A.SIMBOL, A.NUME
HAVING COUNT(B.ID_TRANZACTIE)>0
ORDER BY COUNT(B.ID_TRANZACTIE) DESC, A.SIMBOL;


SELECT A.ID_TRANZACTIE, DECODE(B.TIP_DOCUMENT, 1, 'Factura fiscala', 2, 'Nota Contabila', 3, 'Chitanta', 4, 'Ordin de plata', 5, 'Bon de consum', 6, 'Extras de cont', 'Alt document') TIP_DOCUMENT_CUVINTE
FROM TRANZACTII A JOIN DOCUMENTE B
ON A.ID_DOCUMENT=B.ID_DOCUMENT;


SELECT ID_DOCUMENT, CASE WHEN TIP_DOCUMENT=1 THEN 'Factura fiscala'
WHEN TIP_DOCUMENT=2 THEN 'Nota contabila'
WHEN TIP_DOCUMENT=3 THEN 'Chitanta'
WHEN TIP_DOCUMENT=4 THEN 'Ordin de plata'
WHEN TIP_DOCUMENT=5 THEN 'Bon de consum'
WHEN TIP_DOCUMENT=6 THEN 'Extras de cont' 
ELSE 'Alt document' END TIP_DOCUMENT_CUVINTE
FROM DOCUMENTE;

SELECT COUNT(*) NUMAR,SUM(A.SUMA) SUMA_TOTALA 
FROM TRANZACTII A JOIN DOCUMENTE B
ON A.ID_DOCUMENT=B.ID_DOCUMENT
WHERE DATA_DOCUMENT BETWEEN TO_DATE('01.12.2021', 'DD.MM.YYYY') AND TO_DATE('15.12.2021', 'DD.MM.YYYY');

SELECT A.ID_TRANZACTIE, A.ID_CONTABIL, A.SUMA
FROM TRANZACTII A JOIN CONTABILI B
ON A.ID_CONTABIL=B.ID_CONTABIL
WHERE A.SUMA>=1000 AND B.ID_CONTABIL IN (1,2,3);

SELECT ID_CONTABIL, NUME, PRENUME FROM CONTABILI
WHERE SYSDATE-DATA_ANGAJARII>=270;

SELECT ID_CONTABIL,LPAD(' ',LEVEL*2-2)||NUME||' '|| PRENUME NUME_COMPLET, ID_COORDONATOR, LEVEL
FROM CONTABILI
CONNECT BY PRIOR ID_CONTABIL=ID_COORDONATOR
START WITH ID_CONTABIL=0
MINUS
SELECT ID_CONTABIL,LPAD(' ',(LEVEL+1)*2-2)||NUME||' '|| PRENUME NUME_COMPLET, ID_COORDONATOR, LEVEL+1
FROM CONTABILI
CONNECT BY PRIOR ID_CONTABIL=ID_COORDONATOR
START WITH ID_CONTABIL=2;


SELECT ID_CONTABIL,NUME||' '|| PRENUME NUME_COMPLET, SYS_CONNECT_BY_PATH(NUME||' '||PRENUME,'->') IERARHIE
FROM CONTABILI
WHERE ID_CONTABIL IN (3,5,9)
CONNECT BY PRIOR ID_CONTABIL=ID_COORDONATOR
START WITH ID_CONTABIL=0;

SELECT A.ID_CONTABIL, A.NUME, A.PRENUME,COUNT(B.ID_TRANZACTIE)*NVL(A.VENIT_PE_TRANZACTIE,0)+A.SALARIU VENIT_TOTAL
FROM CONTABILI A LEFT JOIN TRANZACTII B
ON A.ID_CONTABIL=B.ID_CONTABIL
JOIN DOCUMENTE C
ON B.ID_DOCUMENT=C.ID_DOCUMENT
WHERE A.ID_CONTABIL!=0
AND TO_CHAR(C.DATA_DOCUMENT, 'YYYY.MM.DD') BETWEEN '2021.12.01' AND '2021.12.31'
GROUP BY A.ID_CONTABIL, A.NUME, A.PRENUME,NVL(A.VENIT_PE_TRANZACTIE,0),A.SALARIU
ORDER BY VENIT_TOTAL DESC; 

SELECT * FROM CONTABILI
WHERE EXTRACT(MONTH FROM DATA_ANGAJARII)=(SELECT EXTRACT (MONTH FROM DATA_ANGAJARII)FROM CONTABILI WHERE ID_CONTABIL =1)
AND EXTRACT(YEAR FROM DATA_ANGAJARII)=(SELECT EXTRACT (YEAR FROM DATA_ANGAJARII)FROM CONTABILI WHERE ID_CONTABIL =1)
AND ID_CONTABIL!=1;


SELECT * FROM CONTABILI A
WHERE A.SALARIU>(SELECT AVG(B.SALARIU) FROM CONTABILI B WHERE B.ID_COORDONATOR=A.ID_COORDONATOR);


SELECT * FROM CONTABILI
WHERE SUBSTR(UPPER(NUME),-4,4)='ESCU';

INSERT INTO CONTABILI(ID_CONTABIL, NUME, PRENUME, DATA_ANGAJARII, ID_COORDONATOR, SALARIU) VALUES(SEQ_CONTABILI.NEXTVAL, 'Andreescu', 'Maria', TO_DATE('12.12.2021', 'DD.MM.YYYY'), 2, (SELECT SALARIU+150 FROM CONTABILI WHERE ID_CONTABIL=4));

UPDATE CONTABILI SET SALARIU=(SELECT SALARIU+500 FROM CONTABILI WHERE ID_CONTABIL=2) WHERE ID_CONTABIL=3;

DELETE FROM CONTABILI 
WHERE EXTRACT(MONTH FROM DATA_ANGAJARII)=
(SELECT EXTRACT(MONTH FROM DATA_ANGAJARII) FROM CONTABILI WHERE UPPER(NUME)='ANDREESCU' AND UPPER(PRENUME)='MARIA') 
AND EXTRACT(YEAR FROM DATA_ANGAJARII)=
(SELECT EXTRACT(YEAR FROM DATA_ANGAJARII) FROM CONTABILI WHERE UPPER(NUME)='ANDREESCU' AND UPPER(PRENUME)='MARIA');

CREATE VIEW TRANZACTII_DECEMBRIE AS
SELECT A.ID_TRANZACTIE, A.ID_DOCUMENT, B.DATA_DOCUMENT, A.ID_CONTABIL, A.CONT_DEBIT,A.CONT_CREDIT, A.SUMA
FROM TRANZACTII A JOIN DOCUMENTE B
ON A.ID_DOCUMENT=B.ID_DOCUMENT
WHERE TO_CHAR(DATA_DOCUMENT, 'YYYY.MM.DD') BETWEEN '2021.12.01' AND '2021.12.31';