#!/bin/sh
# This script was generated using Makeself 2.1.5

CRCsum="2911367949"
MD5="6a044db30688ea68fd5be87815011645"
TMPROOT=${TMPDIR:=/tmp}

label="The ownCloud setup script"
script="./owncloud.sh"
scriptargs=""
targetdir="scripts"
filesizes="3036"
keep=y

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_Progress()
{
    while read a; do
	MS_Printf .
    done
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
	df -kP "$1" | tail -1 | awk '{print $4}'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_Help()
{
    cat << EOH >&2
Makeself version 2.1.5
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive
 
 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target NewDirectory Extract in NewDirectory
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || type md5`
	test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || type digest`
    PATH="$OLD_PATH"

    MS_Printf "Verifying archive integrity..."
    offset=`head -n 402 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$MD5_PATH"; then
			if test `basename $MD5_PATH` = digest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test $md5 = "00000000000000000000000000000000"; then
				test x$verb = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test "$md5sum" != "$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x$verb = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test $crc = "0000000000"; then
			test x$verb = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test "$sum1" = "$crc"; then
				test x$verb = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc"
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    echo " All good."
}

UnTAR()
{
    tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
}

finish=true
xterm_loop=
nox11=n
copy=none
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 32 KB
	echo Compression: gzip
	echo Date of packaging: Tue Mar 25 21:13:00 GMT 2014
	echo Built with Makeself version 2.1.5 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--notemp\" \\
    \"scripts/\" \\
    \"syncloud_setup.sh\" \\
    \"The ownCloud setup script\" \\
    \"./owncloud.sh\""
	if test x$script != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"y" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\"scripts\"
	echo KEEP=y
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=32
	echo OLDSKIP=403
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 402 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 402 "$0" | wc -c | tr -d " "`
	arg1="$2"
	shift 2
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - $*
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir=${2:-.}
	shift 2
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --xwin)
	finish="echo Press Return to close this window...; read junk"
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

case "$copy" in
copy)
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test "$nox11" = "n"; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm rxvt dtterm eterm Eterm kvt konsole aterm"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test "$targetdir" = "."; then
    tmpdir="."
else
    if test "$keep" = y; then
	echo "Creating directory $targetdir" >&2
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp $tmpdir || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target OtherDirectory' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x$SETUP_NOCHECK != x1; then
    MS_Check "$0"
fi
offset=`head -n 402 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 32 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

MS_Printf "Uncompressing $label"
res=3
if test "$keep" = n; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test $leftspace -lt 32; then
    echo
    echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (32 KB)" >&2
    if test "$keep" = n; then
        echo "Consider setting TMPDIR to a directory with more free space."
   fi
    eval $finish; exit 1
fi

for s in $filesizes
do
    if MS_dd "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; UnTAR x ) | MS_Progress; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
echo

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$verbose" = xy; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval $script $scriptargs $*; res=$?;
		fi
    else
		eval $script $scriptargs $*; res=$?
    fi
    if test $res -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test "$keep" = n; then
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
‹ \ñ1SíksÚHÒŸõ+z	uØ¹HüÚr{Äà„:|€7—2>•ĞE¯èaÌnö¿_÷Œ$ÄÃÙäjã«½RoÖ MwÏô»gEİûîPE8=>¦ÏÚéq5ÿ™Â^­~X;:<­ÒûÓúééï=Äa¤ {oòE¼ßÿ“‚¢N</R"æøö÷´ÿÉÑÑ“ö¯rû×ªõãÃÃ½j­vX=Úƒjaÿï/~P'–«Nôp2“$öÈ¨7A}ĞÕöfj¸tÛ‹Mû	¾(µæ_êRÈ"%éãè®BäÁ„¡Ä3Ás!e &{°ÄÂ¹Û&¡N˜í-$7òM=b Çà{­à³â3i¯€ïÿŞBØG	çÿ“üa|²ÿkµc,	Eü?süÿC™sJƒØu-wÓÀsÎ |ó¾]’$k
wwPîÜvÛ »ªpÿ¢9s% „£¹Bh–ƒª¥bôŒû’È„şhEP“¦–$½ëG½Öu§QŞ]İÁ$àHÒğCïâªÛÖFışÕP»iŞ5Ô8¤¤dè6_tšY$Ã9ÀÔãÙ!”wJÒ›~¤/İ›‘&æÚ&Ja8—¤ÀA†S(o’ÑL«z¹k|îx&*rÇfÉX$9_7>ê3JºÉ3Ê¡ËdˆPÍiÿñÄbOLX0p&TÌ¯Së¦lAXî,DO½€å¢#Û6Y#ú‚ë%±Xª`h@iÅ²´f>xÁùrå2XèÙ?ä#â.Ôæj·Cåvt)ÿ(%T¸0Ós+‘X³?Ù CšTR_Hò}²HÀR%ÃZ³˜–q^9mÌñĞd?fLp•C<° y0l‹¹Qú€ÕÇs7™èqä	F»F›é‚$1¶¨xÖDå<·G°®Fáu%dQDZwtƒò*ˆŠ…ÀP¸ò8¶~‡,šˆÑûJĞlîpŠ”Ÿ;ƒa·ßCR­ÛZWWŠnFxq'¾}Ö}?$ÁïAj·F­vwĞPÑ·t©ÿ^ÌÌC©Â…Z,Yş¯HyL-e‡9`¨«³?Ô’%`¬âˆ–Œ€4ÚmoXYæàä„m6±twÍCtÙ‚J¨.æŒı²Tÿz´˜:«€Ê"CÅ¥©¡Û
Éc„BÑbÆ	àß@,ª¨Lè‘¼°"ô¹HÖÃdŒZ28DAÌJğ›‘	9 :U„ÿÛÌˆ,Ï×¹é3Ÿşa¼É‚;#Ş¥2L=Ûdä|4­ Ê‰sÖ8^Œ?7y.H.®ÛÚuÿ¶7z×n7Jş×çîL…*'GjÅ_füK4ù2$‘’4|©«ãmLŠD9?é^›_8u‹>‹ú@Q@„;'1~ÿş=½¸ì_µ;ƒÆî¸AjRšĞ†Î¶@)Ïü¼‰LO´6ïÓR	+PÛ%É[rMKÒöÄLT.ÒGŒ»BÑŸû²îàX®û.~Ã.ygĞêúÜ’MQV¤è›Kä'D@DO³À‹ıµôOêâ¦àÔ$Çæˆ…©ºÉ:ÈoÅ Gåı"›ÜYÿqû¤*ù‚§¯‡áÂ¸ÏÒÛƒDåùÌ.+Çk©^%L-#Í¾ˆNâÉ8ûfÎš>Ó-÷«ùïPøÖd±û‹å“êEåLcá÷U/j‘P}’@„æÉù&”{É9‰PM“’ês»È>ÿ8?ïô/¯? ¥t1è´F¸vPÉÊÂß*¼†Í=ª2İv§7ê^v;mxó!‡ô:%&Ç~Óv {	½ş:ÿìGÃÌ¯_Ko­Ş°tÁÍ ûs÷ªó¶3„~/ÃP^Â¨ÿíÓgBä<1¦UıIÊ¡Ú¡R=YÕ È7>vTz-QÒQlæº1;`øÇÀy|U}ƒl5X}¯1"ÿLUM|k{º©x>sC´ízUÂ-,âTt¬ğá,íèÎ(™Æ®-U1‡vªT%f‡ì{LñxË¥ÔrŠã·àŞ/»lÌ™ñQ6XYSËàøO}lÿÊk+Q¢P>²%†Å}#¯—“hÅPÛ$³ïîâ¯˜«]+o$œ=¹u3ºt.ód~À¦,`.’J7¢ï>ƒ—Òå
?Ã¸ß© Âoq¢åœÔªRÂ}•q“
Ë\)‰ûaÛDªdt*²å‘ß’°ÊÉ¼¢|}rHI¸¹òşZ5çıÄ)Óbëâ]g¥D­\WÑYX(cÂ·l}b³•(EJçmÅEwZÂVcÙDŞ-Ûö}Ìe2z’ÎÕŒ¤)‰)Q³u´ N”SÔº»ã²¾­e[¸ÕÌ¦Ş^LéÛäÂmÃÖ’DÎ5­ğ!ôœÕPó-%½¬Ì ¤›lªÇv¤1—ĞÇjSÅ5”ó½¸JD*NéFÒ“åN=•ş(ı_²Ã-›k¢ğ;áê;¸¥>s;ê_ô(òÖ‰Å&Oå.şUÁ.F:ÿ‰şËœªß»ì¾E«êA /÷Qã%s-}ì¤h4“j^zb˜N	Ö†3ë¾k¼¤'ƒTŸ¤:³6˜UŸ#uÚR†‘5¯¤ƒ×R¢	rìb‹3Yvî¤0Ù€wÖqé¥Zƒ—É¨§Pş5¯¿ßT¢&©!IYÉ¥U„K†¹Ã`i’şÔ—ê@ˆ… ĞÊw.ñ}ÛÉNOTê%5ß"ÍAR4²£‡dkd •··œÔgÆ=Ïé¶M='hª:Œ·}ªÊö$OùåNV®Y+Nc~5+‰š::¶NòàÎk…0¯ÁL`x˜Ú–˜‹0)ÏæI[œ†ÆÏ­wİ,ëĞˆšP†¹³Wñ#'dF{	ìCÌÑX:0’mÏeŠëU~jJç?´û£7t2¯0ü0u®¡$úÿdL1#³„4k¨”“Ï)Œšiİ?Wù#½O0›¼ºœS,65r"E‹ÿ\å/Ä©®ùcõ\å_üÇˆ—¾Àlúz4odB"åjˆæQ³‰²¯éê¸ÒrÊÏmh Ù…§[¼Ü>ï.Ò3—Ì	^À›%$æGk	¶é±\Ÿ£)è$•­0ZÆRú<ÿç›Ïïzüµ÷¿«û¿êÑáQqÿûœöß<JyNû×ê›ö?<9<)îùşGÊÎ‹Ë5)¹É8=­®N!±iY¸ ²æã,Ûšd8ÅêŸ3şsÇÂÏıûŠöø¯ŸàGÿÏ –C­[öû)y—¸…À	ppƒÍ–Å>÷Îxçgo4/ü8Âí[ÊAA
ñr¿2±?Zfå`“Æd¢ãÇåmnJèÛ’İ-ZD¿[=¦ˆg•ƒ»ê=?¤ËÆ€Ÿè~3Ü‹;>Ü¤yT!·8ïÍDß_¿â7ÚêE¢”­Ù7Ğ5}j™+œ]KË¯·‡Ûq‰Ü4zwMƒF*îe,WÓ*‚¥gºKjM=˜=ÜÕ„ä~`¹Q:¾­çË¯#»/hè®¢šìAM½VyéÃ¤V¹|òXÉÌsĞ—=J\»üúş«(¨qGV¿J…98Èx
!óœ‹µ+ÿ¯]A?oÿOy³ÿ«Òï?‹üÿÌıß°3Ò®[Z«İhWı·Òêg€+ÿÀÇä×@ğ?²Ú$ƒüµÇûşàïİŞ[-¹ÈU#ÇÏ1ã(Ée÷:&¡³­¯ê¸‘êÒÙˆ”eà©†¿Ü7üÜUT e‡ÕW‡Ÿõ){„m|Ë1RY;Ãa£¼oš˜Î|Ş8@Ş“°Q«Ö0ƒá’5¨7Å²bÛşì˜Çaì|¦Ó‰J¨şk¼¯(ãƒ/ÿU^–Õju\ÆÇã5)‹É	G©úøÎ\b°Œû±‹ËÃì9.•së—J›Ràg}]¸MM ÆrJØ©¼Ü/[®uZÉï_èò7ò ¿q•¾é*B¥kˆ/ó82ù# ×[ĞI{‘¡( €
( €
( €
( €
( €
( €
( €
( €¾ÿåÔ P  