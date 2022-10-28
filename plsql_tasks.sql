create or replace procedure venituri_totale_contabili(an number)
is
cursor c is select id_contabil, nume, prenume, data_angajarii, salariu, venit_pe_tranzactie from
contabili where extract(year from data_angajarii)=an;
cursor t (p_id_contabil number) is select id_tranzactie from tranzactii where
id_contabil=p_id_contabil;
r c%rowtype;
venit number;
ok boolean:=False;
exceptie_an exception;
exceptie_an_virgula exception;
begin
if(an>extract(year from sysdate)) then
raise exceptie_an;
end if;
if(an!=round(an)) then
raise exceptie_an_virgula;
end if;
open c;
loop
fetch c into r;
exit when c%notfound;
ok:=True;
venit:=r.salariu*round(months_between(sysdate, r.data_angajarii));
for tr in t(r.id_contabil) loop
venit:=venit+nvl(r.venit_pe_tranzactie,0);
end loop;
dbms_output.put_line('veniturile totale obtinute de contabilul '||r.nume||' '||r.prenume|| ' in
anul '||an||' sunt '||venit||' RON ');
end loop;
close c;
if(ok=False) then
dbms_output.put_line('Nu exista contabili angajati in anul '||an);
end if;
exception
when exceptie_an then
dbms_output.put_line('Anul '||an||' este mai mare decat anul curent!');
when exceptie_an_virgula then
dbms_output.put_line('Anul introdus este gresit, deoarece reprezinta o valoare care nu e numar
intreg!');
end;
/

set serveroutput on;
begin
venituri_totale_contabili(2021);
exception
when value_error then
dbms_output.put_line('Anul introdus este gresit! Acesta trebuie sa fie un numar intreg, nu alt tip
de data!');
end;
/
set serveroutput on;
begin
venituri_totale_contabili(2021.5);
exception
when value_error then
dbms_output.put_line('Anul introdus este gresit! Acesta trebuie sa fie un numar intreg, nu alt tip
de data!');
end;
/
set serveroutput on;
begin
venituri_totale_contabili(2025);
exception
when value_error then
dbms_output.put_line('Anul introdus este gresit! Acesta trebuie sa fie un numar intreg, nu alt tip
de data!');
end;
/
set serveroutput on;
begin
venituri_totale_contabili('ab');
exception
when value_error then
dbms_output.put_line('Anul introdus este gresit! Acesta trebuie sa fie un numar intreg, nu alt tip
de data!');
end;
/

create or replace procedure debitari_creditari (an number, luna number)
as
cursor cont is select simbol, nume from plan_conturi order by simbol;
debitari number;
creditari number;
exceptie_an exception;
exceptie_luna exception;
exceptie_virgula exception;
begin
if(luna>12 or luna<1) then
raise exceptie_luna;
end if;
if(an>extract(year from sysdate)) then
raise exceptie_an;
end if;
if(an!=round(an) or luna!=round(luna)) then
raise exceptie_virgula;
end if;
for c in cont loop
select count(id_tranzactie) into debitari from tranzactii a
join documente d
on a.id_document=d.id_document
where cont_debit=c.simbol
and extract (year from data_document)=an
and extract (month from data_document)=luna;
select count(id_tranzactie) into creditari from tranzactii a
join documente d
on a.id_document=d.id_document
where cont_credit=c.simbol
and extract (year from data_document)=an
and extract (month from data_document)=luna;
if(creditari>0 or debitari >0) then
dbms_output.put_line('in luna '||luna||' a anului '||an||' contul '||c.simbol||' - '||c.nume||'
a fost creditat de '||creditari||' ori si debitat de '||debitari||' ori.');
end if;
end loop;
exception
when exceptie_an then
dbms_output.put_line('Anul '||an||' este mai mare decat anul curent!');
when exceptie_luna then
dbms_output.put_line('Parametrul pentru luna trebuie sa fie intre 1 si 12!');
when exceptie_virgula then
dbms_output.put_line('Anul introdus este gresit, sau luna introdusa este gresita, deoarece
reprezinta o valoare care nu e numar intreg!');
end;
/

begin
debitari_creditari(2021, 12);
end;
/
begin
debitari_creditari(2021, 13);
end;
/

create or replace function tranzactii_subordonati(p_id_coordonator number, p_an number)
return number
is
cursor t is select id_tranzactie, a.id_contabil, id_coordonator from tranzactii a join documente d
on a.id_document=d.id_document join contabili e on a.id_contabil=e.id_contabil
where extract(year from d.data_document)=p_an;
contor number:=0;
exceptie_an exception;
exceptie_virgula exception;
coordonator number;
begin
if(p_an>extract(year from sysdate)) then
raise exceptie_an;
end if;
if(p_an!=round(p_an)) then
raise exceptie_virgula;
end if;
select id_contabil into coordonator from contabili where id_contabil=p_id_coordonator;
for tr in t loop
if tr.id_coordonator=coordonator then
contor:=contor+1;
end if;
end loop;
return contor;
exception
when exceptie_an then
dbms_output.put_line('Anul '||p_an||' este mai mare decat anul curent!');
return -1;
when exceptie_virgula then
dbms_output.put_line('Anul introdus este gresit, deoarece reprezinta o valoare care nu e numar
intreg!');
return -1;
when no_data_found then
dbms_output.put_line('Coordonatorul introdus nu exista!');
return -1;
end;
/

declare
nr_tranzactii number;
begin
nr_tranzactii:=tranzactii_subordonati(0, 2021);
dbms_output.put_line('subordonatii coordonatorului cu id 0 au realizat in anul 2021
'||nr_tranzactii|| ' tranzactii');
end;
/
declare
nr_tranzactii number;
begin
nr_tranzactii:=tranzactii_subordonati(88, 2021);
dbms_output.put_line('subordonatii coordonatorului cu id 88 au realizat in anul 2021
'||nr_tranzactii|| ' tranzactii');
end;
/

create or replace function venituri_totale_echipa(p_id_coordonator number, luna number, an
number)
return number
is
cursor c is select id_contabil from contabili where id_coordonator=p_id_coordonator;
cursor t(p_id_contabil number) is select suma from tranzactii a join documente d on
a.id_document=d.id_document where id_contabil=p_id_contabil and extract (year from
data_document)=an
and extract (month from data_document)=luna;
total number:=0;
exceptie_an exception;
exceptie_luna exception;
exceptie_virgula exception;
coordonator number;
begin
if(luna>12 or luna<1) then
raise exceptie_luna;
end if;
if(an>extract(year from sysdate)) then
raise exceptie_an;
end if;
if(an!=round(an) or luna!=round(luna)) then
raise exceptie_virgula;
end if;
select id_contabil into coordonator from contabili where id_contabil=p_id_coordonator;
for w in t(coordonator) loop
total:=total+w.suma;
end loop;
for r in c loop
for w in t(r.id_contabil) loop
total:=total+w.suma;
end loop;
end loop;
return total;
exception
when exceptie_an then
dbms_output.put_line('Anul '||an||' este mai mare decat anul curent!');
return -1;
when exceptie_luna then
dbms_output.put_line('Parametrul pentru luna trebuie sa fie intre 1 si 12!');
return -1;
when exceptie_virgula then
dbms_output.put_line('Anul introdus este gresit, sau luna introdusa este gresita, deoarece
reprezinta o valoare care nu e numar intreg!');
return -1;
when no_data_found then
dbms_output.put_line('Coordonatorul introdus nu exista!');
return -1;
end;
/

declare
total number;
begin
total:=venituri_totale_echipa(0, 11, 2021);
dbms_output.put_line('coordonatorul cu id 0 si subordonatii sai au inregistrat in luna 11 a anului
2021 tranzactii in valoare de '||total|| ' RON');
end;
/

create or replace function prima_Craciun(p_id_contabil number, an number)
return number
is
valoare_prima number:=0;
type id_suma_tranz is record(id tranzactii.id_tranzactie%type, suma tranzactii.suma%type);
type t_tranz is table of id_suma_tranz;
tranz t_tranz;
exceptie_an exception;
exceptie_virgula exception;
contabil number;
begin
if(an>extract(year from sysdate)) then
raise exceptie_an;
end if;
if(an!=round(an)) then
raise exceptie_virgula;
end if;
select id_contabil into contabil from contabili where id_contabil=p_id_contabil;
select id_tranzactie,suma bulk collect into tranz from tranzactii a join documente d on
a.id_document=d.id_document where id_contabil=contabil and extract (year from
data_document)=an;
for i in 1..sql%rowcount loop
valoare_prima:=valoare_prima+0.5*tranz(i).suma/100;
end loop;
return valoare_prima;
exception
when exceptie_an then
dbms_output.put_line('Anul '||an||' este mai mare decat anul curent!');
return -1;
when exceptie_virgula then
dbms_output.put_line('Anul introdus este gresit, sau luna introdusa este gresita, deoarece
reprezinta o valoare care nu e numar intreg!');
return -1;
when no_data_found then
dbms_output.put_line('Contabilul introdus nu exista!');
return -1;
end;
/

declare
total number;
begin
total:=prima_Craciun(1,2021);
dbms_output.put_line('contabilul cu id 1 va primi de Craciun o prima in valoare de '||total|| ' RON');
end;
/
declare
total number;
begin
total:=prima_Craciun(123,2021);
dbms_output.put_line('contabilul cu id 123 va primi de Craciun o prima in valoare de '||total|| '
RON');
end;
/

create or replace package p_situatii_contabile
is
function rulaj_creditor(p_cont number, p_an number, p_luna number) return number;
function rulaj_debitor(p_cont number, p_an number, p_luna number) return number;
function sold_initial_creditor(p_cont number, p_an number, p_luna number) return number;
function sold_initial_debitor(p_cont number, p_an number, p_luna number) return number;
function total_sume_creditoare(p_cont number, p_an number, p_luna number) return number;
function total_sume_debitoare(p_cont number, p_an number, p_luna number) return number;
function sold_final_creditor(p_cont number, p_an number, p_luna number) return number;
function sold_final_debitor(p_cont number, p_an number, p_luna number) return number;
procedure balanta_verificare(p_an number, p_luna number);
procedure bilant(p_an number);
procedure cont_profit_pierdere (p_an number);
end;

create or replace package body p_situatii_contabile
is
function rulaj_creditor(p_cont number, p_an number, p_luna number) return number
is
rulaj_c number;
exceptie_an exception;
exceptie_luna exception;
exceptie_virgula exception;
exceptie_cont exception;
pragma exception_init(exceptie_cont, -20600);
begin
if(p_cont<0) then
raise_application_error(-20600, 'Cont invalid!');
end if;
if(p_luna>12 or p_luna<1) then
raise exceptie_luna;
end if;
if(p_an>extract(year from sysdate)) then
raise exceptie_an;
end if;
if(p_an!=round(p_an) or p_luna!=round(p_luna)) then
raise exceptie_virgula;
end if;
select nvl(sum(suma),0) into rulaj_c from tranzactii a
join documente d
on a.id_document=d.id_document
where cont_credit=p_cont
and extract (year from data_document)=p_an
and extract (month from data_document)=p_luna;
return rulaj_c;
exception
when exceptie_an then
dbms_output.put_line('Anul '||p_an||' este mai mare decat anul curent!');
return -1;
when exceptie_luna then
dbms_output.put_line('Parametrul pentru luna trebuie sa fie intre 1 si 12!');
return -1;
when exceptie_virgula then
dbms_output.put_line('Anul introdus este gresit, sau luna introdusa este gresita, deoarece
reprezinta o valoare care nu e numar intreg!');
return -1;
end rulaj_creditor;
function rulaj_debitor(p_cont number, p_an number, p_luna number) return number
is
rulaj_d number;
exceptie_an exception;
exceptie_luna exception;
exceptie_virgula exception;
exceptie_cont exception;
pragma exception_init(exceptie_cont, -20600);
begin
if(p_cont<0) then
raise_application_error(-20600, 'Cont invalid!');
end if;
if(p_luna>12 or p_luna<1) then
raise exceptie_luna;
end if;
if(p_an>extract(year from sysdate)) then
raise exceptie_an;
end if;
if(p_an!=round(p_an) or p_luna!=round(p_luna)) then
raise exceptie_virgula;
end if;
select nvl(sum(suma),0) into rulaj_d from tranzactii a
join documente d
on a.id_document=d.id_document
where cont_debit=p_cont
and extract (year from data_document)=p_an
and extract (month from data_document)=p_luna;
return rulaj_d;
exception
when exceptie_an then
dbms_output.put_line('Anul '||p_an||' este mai mare decat anul curent!');
return -1;
when exceptie_luna then
dbms_output.put_line('Parametrul pentru luna trebuie sa fie intre 1 si 12!');
return -1;
when exceptie_virgula then
dbms_output.put_line('Anul introdus este gresit, sau luna introdusa este gresita, deoarece
reprezinta o valoare care nu e numar intreg!');
return -1;
end rulaj_debitor;
function sold_initial_creditor(p_cont number, p_an number, p_luna number) return number
is
sold_i_c number;
exceptie_an exception;
exceptie_luna exception;
exceptie_virgula exception;
exceptie_cont exception;
pragma exception_init(exceptie_cont, -20600);
begin
if(p_cont<0) then
raise_application_error(-20600, 'Cont invalid!');
end if;
if(p_luna>12 or p_luna<1) then
raise exceptie_luna;
end if;
if(p_an>extract(year from sysdate)) then
raise exceptie_an;
end if;
if(p_an!=round(p_an) or p_luna!=round(p_luna)) then
raise exceptie_virgula;
end if;
if (p_luna=1) then
sold_i_c:=0;
else
sold_i_c:=sold_final_creditor(p_cont, p_an, p_luna-1);
end if;
return sold_i_c;
exception
when exceptie_an then
dbms_output.put_line('Anul '||p_an||' este mai mare decat anul curent!');
return -1;
when exceptie_luna then
dbms_output.put_line('Parametrul pentru luna trebuie sa fie intre 1 si 12!');
return -1;
when exceptie_virgula then
dbms_output.put_line('Anul introdus este gresit, sau luna introdusa este gresita, deoarece
reprezinta o valoare care nu e numar intreg!');
return -1;
end sold_initial_creditor;
function sold_initial_debitor(p_cont number, p_an number, p_luna number) return number
is
exceptie_an exception;
exceptie_luna exception;
exceptie_virgula exception;
exceptie_cont exception;
pragma exception_init(exceptie_cont, -20600);
sold_i_d number;
begin
if(p_cont<0) then
raise_application_error(-20600, 'Cont invalid!');
end if;
if(p_luna>12 or p_luna<1) then
raise exceptie_luna;
end if;
if(p_an>extract(year from sysdate)) then
raise exceptie_an;
end if;
if(p_an!=round(p_an) or p_luna!=round(p_luna)) then
raise exceptie_virgula;
end if;
if (p_luna=1) then
sold_i_d:=0;
else
sold_i_d:=sold_final_debitor(p_cont, p_an, p_luna-1);
end if;
return sold_i_d;
exception
when exceptie_an then
dbms_output.put_line('Anul '||p_an||' este mai mare decat anul curent!');
return -1;
when exceptie_luna then
dbms_output.put_line('Parametrul pentru luna trebuie sa fie intre 1 si 12!');
return -1;
when exceptie_virgula then
dbms_output.put_line('Anul introdus este gresit, sau luna introdusa este gresita, deoarece
reprezinta o valoare care nu e numar intreg!');
return -1;
end sold_initial_debitor;
function total_sume_creditoare(p_cont number, p_an number, p_luna number) return number
is
total_s_c number;
exceptie_an exception;
exceptie_luna exception;
exceptie_virgula exception;
exceptie_cont exception;
pragma exception_init(exceptie_cont, -20600);
begin
if(p_cont<0) then
raise_application_error(-20600, 'Cont invalid!');
end if;
if(p_luna>12 or p_luna<1) then
raise exceptie_luna;
end if;
if(p_an>extract(year from sysdate)) then
raise exceptie_an;
end if;
if(p_an!=round(p_an) or p_luna!=round(p_luna)) then
raise exceptie_virgula;
end if;
total_s_c:=sold_initial_creditor(p_cont, p_an, p_luna)+rulaj_creditor(p_cont, p_an, p_luna);
return total_s_c;
exception
when exceptie_an then
dbms_output.put_line('Anul '||p_an||' este mai mare decat anul curent!');
return -1;
when exceptie_luna then
dbms_output.put_line('Parametrul pentru luna trebuie sa fie intre 1 si 12!');
return -1;
when exceptie_virgula then
dbms_output.put_line('Anul introdus este gresit, sau luna introdusa este gresita, deoarece
reprezinta o valoare care nu e numar intreg!');
return -1;
end total_sume_creditoare;
function total_sume_debitoare(p_cont number, p_an number, p_luna number) return number
is
total_s_d number;
exceptie_an exception;
exceptie_luna exception;
exceptie_virgula exception;
exceptie_cont exception;
pragma exception_init(exceptie_cont, -20600);
begin
if(p_cont<0) then
raise_application_error(-20600, 'Cont invalid!');
end if;
if(p_luna>12 or p_luna<1) then
raise exceptie_luna;
end if;
if(p_an>extract(year from sysdate)) then
raise exceptie_an;
end if;
if(p_an!=round(p_an) or p_luna!=round(p_luna)) then
raise exceptie_virgula;
end if;
total_s_d:=sold_initial_debitor(p_cont, p_an, p_luna)+rulaj_debitor(p_cont, p_an, p_luna);
return total_s_d;
exception
when exceptie_an then
dbms_output.put_line('Anul '||p_an||' este mai mare decat anul curent!');
return -1;
when exceptie_luna then
dbms_output.put_line('Parametrul pentru luna trebuie sa fie intre 1 si 12!');
return -1;
when exceptie_virgula then
dbms_output.put_line('Anul introdus este gresit, sau luna introdusa este gresita, deoarece
reprezinta o valoare care nu e numar intreg!');
return -1;
end total_sume_debitoare;
function sold_final_creditor(p_cont number, p_an number, p_luna number) return number
is
sold_f_c number;
exceptie_an exception;
exceptie_luna exception;
exceptie_virgula exception;
exceptie_cont exception;
pragma exception_init(exceptie_cont, -20600);
begin
if(p_cont<0) then
raise_application_error(-20600, 'Cont invalid!');
end if;
if(p_luna>12 or p_luna<1) then
raise exceptie_luna;
end if;
if(p_an>extract(year from sysdate)) then
raise exceptie_an;
end if;
if(p_an!=round(p_an) or p_luna!=round(p_luna)) then
raise exceptie_virgula;
end if;
if (total_sume_creditoare(p_cont, p_an, p_luna)>total_sume_debitoare(p_cont, p_an, p_luna))
then
sold_f_c:=total_sume_creditoare(p_cont, p_an, p_luna)-total_sume_debitoare(p_cont, p_an,
p_luna);
else
sold_f_c:=0;
end if;
return sold_f_c;
exception
when exceptie_an then
dbms_output.put_line('Anul '||p_an||' este mai mare decat anul curent!');
return -1;
when exceptie_luna then
dbms_output.put_line('Parametrul pentru luna trebuie sa fie intre 1 si 12!');
return -1;
when exceptie_virgula then
dbms_output.put_line('Anul introdus este gresit, sau luna introdusa este gresita, deoarece
reprezinta o valoare care nu e numar intreg!');
return -1;
end sold_final_creditor;
function sold_final_debitor(p_cont number, p_an number, p_luna number) return number
is
sold_f_d number;
exceptie_an exception;
exceptie_luna exception;
exceptie_virgula exception;
exceptie_cont exception;
pragma exception_init(exceptie_cont, -20600);
begin
if(p_cont<0) then
raise_application_error(-20600, 'Cont invalid!');
end if;
if(p_luna>12 or p_luna<1) then
raise exceptie_luna;
end if;
if(p_an>extract(year from sysdate)) then
raise exceptie_an;
end if;
if(p_an!=round(p_an) or p_luna!=round(p_luna)) then
raise exceptie_virgula;
end if;
if (total_sume_debitoare(p_cont, p_an, p_luna)>total_sume_creditoare(p_cont, p_an, p_luna))
then
sold_f_d:=total_sume_debitoare(p_cont, p_an, p_luna)-total_sume_creditoare(p_cont, p_an,
p_luna);
else
sold_f_d:=0;
end if;
return sold_f_d;
exception
when exceptie_an then
dbms_output.put_line('Anul '||p_an||' este mai mare decat anul curent!');
return -1;
when exceptie_luna then
dbms_output.put_line('Parametrul pentru luna trebuie sa fie intre 1 si 12!');
return -1;
when exceptie_virgula then
dbms_output.put_line('Anul introdus este gresit, sau luna introdusa este gresita, deoarece
reprezinta o valoare care nu e numar intreg!');
return -1;
end sold_final_debitor;
procedure balanta_verificare(p_an number, p_luna number)
is
cursor c is select distinct simbol, nume from plan_conturi p left join tranzactii t
on t.cont_credit=p.simbol or t.cont_debit=p.simbol order by simbol||' ';
total_sid number:=0;
total_sic number:=0;
total_rd number:=0;
total_rc number:=0;
total_tsd number:=0;
total_tsc number:=0;
total_sfd number:=0;
total_sfc number:=0;
sidd number:=0;
sic number:=0;
rd number:=0;
rc number:=0;
tsd number:=0;
tsc number:=0;
sfd number:=0;
sfc number:=0;
exceptie_an exception;
exceptie_luna exception;
exceptie_virgula exception;
begin
if(p_luna>12 or p_luna<1) then
raise exceptie_luna;
end if;
if(p_an>extract(year from sysdate)) then
raise exceptie_an;
end if;
if(p_an!=round(p_an) or p_luna!=round(p_luna)) then
raise exceptie_virgula;
end if;
dbms_output.put_line('BALANTA DE VERIFICARE PENTRU LUNA '||p_luna||', ANUL '||p_an);
dbms_output.put_line('Legenda:');
dbms_output.put_line('SID -> sold initial debitor');
dbms_output.put_line('SIC -> sold initial creditor');
dbms_output.put_line('RD -> rulaj debitor');
dbms_output.put_line('RC -> rulaj creditor');
dbms_output.put_line('TSD -> total sume debitoare');
dbms_output.put_line('TSC -> total sume creditoare');
dbms_output.put_line('SFD -> sold final debitor');
dbms_output.put_line('SFC -> sold final creditor');
for t in c loop
sidd:=sold_initial_debitor(t.simbol, p_an, p_luna);
sic:=sold_initial_creditor(t.simbol, p_an, p_luna);
rd:=rulaj_debitor(t.simbol, p_an, p_luna);
rc:=rulaj_creditor(t.simbol, p_an, p_luna);
tsd:=total_sume_debitoare(t.simbol, p_an, p_luna);
tsc:=total_sume_creditoare(t.simbol, p_an, p_luna);
sfd:=sold_final_debitor(t.simbol, p_an, p_luna);
sfc:=sold_final_creditor(t.simbol, p_an, p_luna);
dbms_output.put_line(t.simbol||' '||t.nume||' SID:'||sidd||' SIC:'||sic||' RD:'|| rd||'
RC:'||rc||' TSD:'||tsd||' TSC:'||tsc ||' SFD:'||sfd||' SFC:'||sfc);
total_sid:=total_sid+sidd;
total_sic:=total_sic+sic;
total_rd:=total_rd+rd;
total_rc:=total_rc+rc;
total_tsd:=total_tsd+tsd;
total_tsc:=total_tsc+tsc;
total_sfd:=total_sfd+sfd;
total_sfc:=total_sfc+sfc;
end loop;
dbms_output.put_line('TOTAL => SID: '||total_sid||' SIC: '||total_sic||' RD: '||total_rd||' RC:
'||total_rc||' TSD: '||total_tsd||' TSC: '||total_tsc||' SFD: '||total_sfd||' SFC: '||total_sfc);
exception
when exceptie_an then
dbms_output.put_line('Anul '||p_an||' este mai mare decat anul curent!');
when exceptie_luna then
dbms_output.put_line('Parametrul pentru luna trebuie sa fie intre 1 si 12!');
when exceptie_virgula then
dbms_output.put_line('Anul introdus este gresit, sau luna introdusa este gresita, deoarece
reprezinta o valoare care nu e numar intreg!');
end balanta_verificare;
procedure cont_profit_pierdere (p_an number)
is
ve number :=0;
ca number :=0;
che number :=0;
re number :=0;
vf number :=0;
chf number :=0;
rf number :=0;
rbe number :=0;
chip number :=0;
rne number :=0;
cursor c is select distinct simbol from plan_conturi p left join tranzactii t
on t.cont_credit=p.simbol or t.cont_debit=p.simbol where p.simbol between 600 and 799
or p.simbol between 6000 and 7999
order by simbol||' ';
luna number;
exceptie_an exception;
exceptie_virgula exception;
begin
if(p_an>extract(year from sysdate)) then
raise exceptie_an;
end if;
if(p_an!=round(p_an)) then
raise exceptie_virgula;
end if;
for r in c loop
luna:=1;
while (luna<=12) loop
case
when r.simbol between 600 and 659 then
che:=che+rulaj_debitor(r.simbol, p_an, luna);
when r.simbol between 6000 and 6599 then
che:=che+rulaj_debitor(r.simbol, p_an, luna);
when r.simbol between 660 and 669 then
chf:=chf+rulaj_debitor(r.simbol, p_an, luna);
when r.simbol between 6600 and 6699 then
chf:=chf+rulaj_debitor(r.simbol, p_an, luna);
when r.simbol between 6811 and 6818 then
che:=che+rulaj_debitor(r.simbol, p_an, luna);
when r.simbol between 6861 and 6868 then
chf:=chf+rulaj_debitor(r.simbol, p_an, luna);
when r.simbol in (691, 695, 698) then
chip:=chip+rulaj_debitor(r.simbol, p_an, luna);
when r.simbol between 700 and 709 or r.simbol between 7000 and 7099 then
ca:=ca+rulaj_creditor(r.simbol, p_an, luna);
ve:=ve+rulaj_creditor(r.simbol, p_an, luna);
when r.simbol between 710 and 759 or r.simbol between 7100 and 7599 then
ve:=ve+rulaj_creditor(r.simbol, p_an, luna);
when r.simbol between 760 and 769 or r.simbol between 7600 and 7699 then
vf:=vf+rulaj_creditor(r.simbol, p_an, luna);
when r.simbol between 7810 and 7819 then
ve:=ve+rulaj_creditor(r.simbol, p_an, luna);
else
vf:=vf+rulaj_creditor(r.simbol, p_an, luna);
end case;
luna:=luna+1;
end loop;
end loop;
re := ve-che;
rf :=vf-chf;
rbe := re+rf;
rne:=rbe-chip;
dbms_output.put_line('CONTUL DE PROFIT SI PIERDERE PENTRU ANUL '||p_an);
dbms_output.put_line('Venituri din exploatare '||ve);
dbms_output.put_line('Cifra de afaceri neta '||ca);
dbms_output.put_line('Cheltuieli de exploatare '||che);
dbms_output.put_line('Rezultatul din exploatare '||re);
dbms_output.put_line('Venituri financiare '||vf);
dbms_output.put_line('Cheltuieli financiare '||chf);
dbms_output.put_line('Rezultatul financiar '||rf);
dbms_output.put_line('Reziltatul brut al exercitiului '||rbe);
dbms_output.put_line('Cheltuieli cu impozitul pe profit '||chip);
dbms_output.put_line('Rezultatul net al exercitiului '||rne);
exception
when exceptie_an then
dbms_output.put_line('Anul '||p_an||' este mai mare decat anul curent!');
when exceptie_virgula then
dbms_output.put_line('Anul introdus este gresit, deoarece reprezinta o valoare care nu e numar
intreg!');
end cont_profit_pierdere;
procedure bilant(p_an number)
is
a_i number :=0;
i_n number :=0;
i_c number :=0;
i_f number :=0;
a_c number :=0;
stoc number :=0;
creante number :=0;
i_ts number :=0;
ccb number :=0;
ch_avans number :=0;
dts number :=0;
acn_dcn number :=0;
ta_m_dts number :=0;
dtl number :=0;
prov number :=0;
v_avans number :=0;
cpr number :=0;
cap_social number :=0;
act_pr number :=0;
pr_cap number :=0;
rez_reev number :=0;
rez number :=0;
rezult_rep number :=0;
rez_ex number :=0;
rep_prof number :=0;
cursor c is select distinct simbol from plan_conturi p left join tranzactii t
on t.cont_credit=p.simbol or t.cont_debit=p.simbol order by simbol||' ';
luna number;
exceptie_an exception;
exceptie_virgula exception;
begin
if(p_an>extract(year from sysdate)) then
raise exceptie_an;
end if;
if(p_an!=round(p_an)) then
raise exceptie_virgula;
end if;
for r in c loop
luna:=1;
while (luna<=12) loop
case
when r.simbol in (1011, 1012)then
cap_social:=cap_social+rulaj_creditor(r.simbol, p_an, luna)-rulaj_debitor(r.simbol, p_an, luna);
when r.simbol in (1091, 1092, 1095) then
act_pr:=act_pr+rulaj_creditor(r.simbol, p_an, luna)-rulaj_debitor(r.simbol, p_an, luna);
when r.simbol between 1041 and 1044 then
pr_cap:=pr_cap+rulaj_creditor(r.simbol, p_an, luna)-rulaj_debitor(r.simbol, p_an, luna);
when r.simbol=105 then
rez_reev:=rez_reev+rulaj_creditor(r.simbol, p_an, luna)-rulaj_debitor(r.simbol, p_an, luna);
when r.simbol in (1061, 1063, 1068) then
rez:=rez+rulaj_creditor(r.simbol, p_an, luna)-rulaj_debitor(r.simbol, p_an, luna);
when r.simbol between 1170 and 1179 then
rezult_rep:=rezult_rep+rulaj_creditor(r.simbol, p_an, luna)-rulaj_debitor(r.simbol, p_an, luna);
when r.simbol=121 then
rez_ex:=rez_ex+rulaj_creditor(r.simbol, p_an, luna)-rulaj_debitor(r.simbol, p_an, luna);
when r.simbol=129 then
rep_prof:=rep_prof+rulaj_creditor(r.simbol, p_an, luna)-rulaj_debitor(r.simbol, p_an, luna);
when r.simbol between 1510 and 1519 then
prov:=prov+rulaj_creditor(r.simbol, p_an, luna)-rulaj_debitor(r.simbol, p_an, luna);
when r.simbol between 1600 and 1699 then
dtl:=dtl++rulaj_creditor(r.simbol, p_an, luna)-rulaj_debitor(r.simbol, p_an, luna);
when r.simbol between 200 and 209 then
i_n:=i_n+rulaj_debitor(r.simbol, p_an, luna)-rulaj_creditor(r.simbol, p_an, luna);
when r.simbol between 2800 and 2809 or r.simbol between 2900 and 2909 then
i_n:=i_n+rulaj_debitor(r.simbol, p_an, luna)-rulaj_creditor(r.simbol, p_an, luna);
when r.simbol between 210 and 219 or r.simbol between 220 and 229 or r.simbol between 230
and 239 then
i_c:=i_c+rulaj_debitor(r.simbol, p_an, luna)-rulaj_creditor(r.simbol, p_an, luna);
when r.simbol between 2810 and 2819 or r.simbol between 2910 and 2919 then
i_c:=i_c+rulaj_debitor(r.simbol, p_an, luna)-rulaj_creditor(r.simbol, p_an, luna);
when r.simbol between 260 and 269 or r.simbol between 2600 and 2699 then
i_f:=i_f+rulaj_debitor(r.simbol, p_an, luna)-rulaj_creditor(r.simbol, p_an, luna);
when r.simbol between 300 and 309 or r.simbol between 3000 and 3099 or r.simbol between
320 and 329 or r.simbol between 340 and 389 then
stoc:=stoc+rulaj_debitor(r.simbol, p_an, luna)-rulaj_creditor(r.simbol, p_an, luna);
when r.simbol between 390 and 399 or r.simbol between 3900 and 3999 then
i_f:=i_f+rulaj_debitor(r.simbol, p_an, luna)-rulaj_creditor(r.simbol, p_an, luna);
when r.simbol between 410 and 419 or r.simbol between 4100 and 4199 or r.simbol = 4424 then
creante:=creante+rulaj_debitor(r.simbol, p_an, luna)-rulaj_creditor(r.simbol, p_an, luna);
when r.simbol between 500 and 509 or r.simbol between 5000 and 5099 then
i_ts:=i_ts+rulaj_debitor(r.simbol, p_an, luna)-rulaj_creditor(r.simbol, p_an, luna);
when r.simbol between 510 and 518 or r.simbol between 5300 and 5499 then
ccb:=ccb+rulaj_debitor(r.simbol, p_an, luna)-rulaj_creditor(r.simbol, p_an, luna);
when r.simbol=471 then
ch_avans:=ch_avans+rulaj_debitor(r.simbol, p_an, luna)-rulaj_creditor(r.simbol, p_an, luna);
when r.simbol between 400 and 408 or r.simbol between 420 and 439 or r.simbol in
(519,4411,4423) then
dts:=dts-rulaj_debitor(r.simbol, p_an, luna)+rulaj_creditor(r.simbol, p_an, luna);
else
v_avans:=v_avans+rulaj_creditor(r.simbol, p_an, luna)-rulaj_debitor(r.simbol, p_an, luna);
end case;
luna:=luna+1;
end loop;
end loop;
a_i := i_n + i_c + i_f;
a_c:=stoc+creante+i_ts+ccb;
acn_dcn:=a_c+ch_avans-dts-v_avans;
ta_m_dts:=acn_dcn+a_i;
cpr :=cap_social+act_pr+pr_cap+rez_reev+rez+rezult_rep +rez_ex +rep_prof;
dbms_output.put_line('BILANTUL PENTRU ANUL '||p_an);
dbms_output.put_line('Active imobilizate '||a_i);
dbms_output.put_line('Imobilizari necorporale '||i_n);
dbms_output.put_line('Imobilizari corporale '||i_c);
dbms_output.put_line('Imobilizari financiare '||i_f);
dbms_output.put_line('Active circulante '||a_c);
dbms_output.put_line('Stocuri '||stoc);
dbms_output.put_line('Creante '||creante);
dbms_output.put_line('Investitii pe termen scurt '||i_ts);
dbms_output.put_line('Casa si conturile la banci '||ccb);
dbms_output.put_line('Cheltuieli in avans '||ch_avans);
dbms_output.put_line('Datorii termen scurt '||dts);
if(acn_dcn>0) then
dbms_output.put_line('Active cirulante nete '||acn_dcn);
else
dbms_output.put_line('Datorii curente nete '||-acn_dcn);
end if;
dbms_output.put_line('Total active minus datorii pe termen scurt '||ta_m_dts);
dbms_output.put_line('Datorii pe termen lung '||dtl);
dbms_output.put_line('Provizioane '||prov);
dbms_output.put_line('Venituri in avans '||v_avans);
dbms_output.put_line('Capitaluri proprii '||cpr);
dbms_output.put_line('Capital social '||cap_social);
dbms_output.put_line('Actiuni proprii '||act_pr);
dbms_output.put_line('Prime de capital '||pr_cap);
dbms_output.put_line('Rezerve din reevaluare '||rez_reev);
dbms_output.put_line('Rezerve '||rez);
dbms_output.put_line('Rezultatul reportat '||rezult_rep);
dbms_output.put_line('Rezultatul exercitiului '||rez_ex);
dbms_output.put_line('Repartizarea profitului '||rep_prof);
exception
when exceptie_an then
dbms_output.put_line('Anul '||p_an||' este mai mare decat anul curent!');
when exceptie_virgula then
dbms_output.put_line('Anul introdus este gresit, deoarece reprezinta o valoare care nu e numar
intreg!');
end bilant;
end;
/

declare
val number;
begin
val:=p_situatii_contabile.rulaj_creditor(5311, 2021, 12);
dbms_output.put_line(val);
val:=p_situatii_contabile.rulaj_debitor(5311, 2021, 12);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_initial_creditor(5311, 2021, 12);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_initial_debitor(5311, 2021, 12);
dbms_output.put_line(val);
val:=p_situatii_contabile.total_sume_creditoare(5311, 2021, 12);
dbms_output.put_line(val);
val:=p_situatii_contabile.total_sume_debitoare(5311, 2021, 12);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_final_creditor(5311, 2021, 12);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_final_debitor(5311, 2021, 12);
dbms_output.put_line(val);
end;
/

declare
val number;
begin
val:=p_situatii_contabile.rulaj_creditor(5311, 2021.1, 13);
dbms_output.put_line(val);
val:=p_situatii_contabile.rulaj_debitor(5311, 2021.1, 13);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_initial_creditor(5311, 2021.1, 13);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_initial_debitor(5311, 2021.1, 13);
dbms_output.put_line(val);
val:=p_situatii_contabile.total_sume_creditoare(5311, 2021.1, 13);
dbms_output.put_line(val);
val:=p_situatii_contabile.total_sume_debitoare(5311, 2021.1, 13);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_final_creditor(5311, 2021.1, 13);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_final_debitor(5311, 2021.1, 13);
dbms_output.put_line(val);
end;
/

declare
val number;
begin
val:=p_situatii_contabile.rulaj_creditor(5311, 2021, 13);
dbms_output.put_line(val);
val:=p_situatii_contabile.rulaj_debitor(5311, 2021, 13);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_initial_creditor(5311, 2021, 13);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_initial_debitor(5311, 2021, 13);
dbms_output.put_line(val);
val:=p_situatii_contabile.total_sume_creditoare(5311, 2021, 13);
dbms_output.put_line(val);
val:=p_situatii_contabile.total_sume_debitoare(5311, 2021, 13);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_final_creditor(5311, 2021, 13);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_final_debitor(5311, 2021, 13);
dbms_output.put_line(val);
end;
/

dbms_output.put_line(val);
val:=p_situatii_contabile.total_sume_debitoare(5311, 2021, 13);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_final_creditor(5311, 2021, 13);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_final_debitor(5311, 2021, 13);
dbms_output.put_line(val);
end;
/
declare
val number;
begin
val:=p_situatii_contabile.rulaj_creditor(-5311, 2021, 12);
dbms_output.put_line(val);
val:=p_situatii_contabile.rulaj_debitor(-5311, 2021, 12);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_initial_creditor(-5311, 2021, 12);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_initial_debitor(-5311, 2021, 12);
dbms_output.put_line(val);
val:=p_situatii_contabile.total_sume_creditoare(-5311, 2021, 12);
dbms_output.put_line(val);
val:=p_situatii_contabile.total_sume_debitoare(-5311, 2021, 12);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_final_creditor(-5311, 2021, 12);
dbms_output.put_line(val);
val:=p_situatii_contabile.sold_final_debitor(-5311, 2021, 12);
dbms_output.put_line(val);
end;
/

begin
p_situatii_contabile.bilant(2021);
end;
/

begin
p_situatii_contabile.bilant(2021.1);
end;
/

begin
p_situatii_contabile.bilant(2025);
end;
/

begin
p_situatii_contabile.cont_profit_pierdere(2021);
end;
/

create or replace trigger modificare_cont_interzisa
before update on plan_conturi
begin
raise_application_error(-20500, 'Datele din planul de conturi nu pot fi modificate!');
end;
/
update plan_conturi set nume='test' where simbol=5311;

create or replace trigger stergere_tranzactii_interzisa
before delete on tranzactii
begin
raise_application_error(-20512, 'Tranzactiile nu pot fi sterse!');
end;
/
delete from tranzactii;

create or replace trigger t_crestere_salariu
before update of salariu on contabili for each row
begin
if( :NEW.salariu > 9000 and :OLD.id_coordonator!=0) then
raise_application_error(-20510, 'Doar subordonatii directi ai contabilului cu id 0 pot avea salariu
peste 9000!');
end if;
end;
/
update contabili set salariu=10000 where id_contabil in (20,21,22);

create or replace trigger t_regularizare_tva
before insert on tranzactii for each row
begin
if( (:NEW.cont_credit = 4423 or :NEW.cont_debit=4424) and extract (day from sysdate)<28) then
raise_application_error(-20510, 'Regularizarea TVA se realizeaza doar incepand cu ziua 28 a lunii');
end if;
end;
/
INSERT INTO TRANZACTII (ID_TRANZACTIE, ID_DOCUMENT,ID_CONTABIL, CONT_DEBIT,
CONT_CREDIT, SUMA) VALUES (SEQ_TRANZACTII.NEXTVAL,5,2,4427,4423,3000);
