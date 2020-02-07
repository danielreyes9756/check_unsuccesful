#!/bin/bash
die()
{
	echo "Error: $1" 1>&2
	exit -1
}

(( $# != 1 )) && die "Cantidad de parametros invalido"
regex="^[0-9]*$"
[[ $1 =~ $regex ]] || die "Este parametro no es valido"

# Si no existe el fichero ponemos la fecha ha 0 para coger todos los valores
# Si exitste en cambio busca la ultima fecha y la transforma a segundos
if [ ! -f /var/log/login_unsuccessful.txt ]
then
	fecha=0
else
	fechaTotal=$(grep "^[-].*[-]$" /var/log/login_unsuccessful.txt | tail -n 1 | tr -d "-")
	fecha=$(date -d "$fechaTotal" "+%s")
	
fi
# Añadimos la fecha del sistema al fichero y cremaos un fichero auxiliar
echo $(date '+-%b %d %H:%M:%S-') >> /var/log/login_unsuccessful.txt
echo "" > /var/log/auxiliar.txt

# En este fichero auxiliar se guardaran todas las lineas valdas (cuya fecha sea mayor que la ultima del fichero)
while read linea 
do	
	fechaAux=$(cut -d" " -f1,2,3 <<< $linea)
	fechaLinea=$(date -d "$fechaAux" "+%s")
	if(( fechaLinea > fecha ))
	then
		x=${linea/"$fechaAux"/''}
		y=$(grep -o " user=.*" <<< $x) 
		x=${x/"$y"/''}				#Suprimimos el usuario al que se intenta conectar (ya que por cada usuario saldria como una String nueva)
		y=$(grep -o " tty=pts/[0-9]*" <<< $x)	
		x=${x/"$y"/''}				#Suprimimos el tty (ya que por cada tty distinto saldria como una String nueva)
		echo $x >> /var/log/auxiliar.txt	
	fi

done < /var/log/secure
#busqueda de las lineas que son authentication failure, ordenadas, "unificadas y contadas"
grep ": authentication failure;" /var/log/auxiliar.txt | sort | uniq -c |
while IFS=" " read num linea
do
	if(( num > $1 ))
	then
		#acceso por comando su
		if(( $(grep "su:auth" <<< $linea | wc -l) > 0))
		then
			uid=$(cut -d" " -f7 <<< $linea) #uid del usuario que intento acceder
			uid=${uid/"uid="/''}
			if(( uid >= 500 ))  #comprobación de usuario distinto del sistema
			then 
				user=$(cut -d" " -f9 <<< $linea) #nombre del usuario que intento acceder
				user=${user/"ruser="/''}
				echo -e "Intentos fallidos mediante el comando su del usuario:"
				# comprobacion de tipo de cuentas, segun su caducidad por contraseña y cuenta
				marca1=$(chage -l $user | grep "Account" | cut -d: -f 2 | tr -d " ") 
				marca2=$(chage -l $user | grep "Password e" | cut -d: -f 2 | tr -d " ")
				if [[ $marca1 != "never" && $marca2 != "never" ]]
				then 
					echo "^^$user" 
				elif [[ $marca1 != "never" && $marca2 == "never" ]]
				then
					echo "^*$xuser"
				elif [[ $marca1 == "never" && $marca2 != "never" ]]
				then
					echo "*^$user"
				else	
					echo "**$user" 
				fi
			fi
		#acceso por "interfaz grafica"	
		elif (( $(grep "gdm-password:auth" <<< $linea | wc -l) > 0 )) 
		then
			echo "Intentos fallidos al iniciar sesión ----> $num"
		#acceso por comando ssh 
		else
			user=$(cut -d" " -f10 <<< $linea) #rhost (ip) que intento acceder
			user=${user/"rhost="/''}
			echo -e "Intentos fallidos mediante el comando ssh por la ip:\n$user"
		fi
	fi
# guardado en el login_unsuccessful.txt y eliminacion del fichero auxiliar
done >> /var/log/login_unsuccessful.txt

rm -f /var/log/auxiliar.txt
exit 0
