#!/usr/bin/env sh
###############################################################################
#░▒█▀▀▀█░▒█▀▀█░▒█▀▀▀░▒█▄░▒█░▒█▀▀▀░▒█▀▀▄░░░░█▀▀░█░░░
#░▒█░░▒█░▒█▄▄█░▒█▀▀▀░▒█▒█▒█░▒█▀▀▀░▒█▄▄▀░▄▄░▀▀▄░█▀▀█
#░▒█▄▄▄█░▒█░░░░▒█▄▄▄░▒█░░▀█░▒█▄▄▄░▒█░▒█░▀▀░▀▀▀░▀░░▀
#	AUTHOR: J. Langedijk
#	DESCRIPTION: file opner (also for nnn)
###############################################################################
# THIS CODE IS INSPIRED BY AND BASED ON THE NUKE PLUGIN OF NNN.
# SEE `$HOME/.config/nnn/plugins/nuke` for more...
###############################################################################
# - TOGGLE GUI ----------------------------------------------------------------
# Set to 1 to enable GUI apps and/or BIN execution
GUI="${GUI:-1}"		# 1 - true;	0 - false
BIN="${BIN:-0}"		# 1 - true;	0 -false

# - EXTRACT FILE DATA ---------------------------------------------------------
FPATH="$1"
FNAME=$(basename "$1")
EDITOR="${VISUAL:-${EDITOR:-vi}}"
PAGER="${PAGER:-less -R}"
ext="${FNAME##*.}"
if [ -n "$ext" ]; then
    ext="$(printf "%s" "${ext}" | tr '[:upper:]' '[:lower:]')"
fi

# - CHECK IF DEVICE IS A MAC (HELL NO!) ---------------------------------------
is_mac() {
    uname | grep -q "Darwin"
}

# - HANDLE PDFs ---------------------------------------------------------------
handle_pdf() {
    if [ "$GUI" -ne 0 ]; then
        if is_mac; then
            nohup open "${FPATH}" >/dev/null 2>&1 &
        elif type zathura >/dev/null 2>&1; then
            nohup zathura "${FPATH}" >/dev/null 2>&1 &
        else
            return
        fi
    elif type pdftotext >/dev/null 2>&1; then
        ## Preview as text conversion
        pdftotext -l 10 -nopgbrk -q -- "${FPATH}" - | eval "$PAGER"
    elif type mutool >/dev/null 2>&1; then
        mutool draw -F txt -i -- "${FPATH}" 1-10 | eval "$PAGER"
    elif type exiftool >/dev/null 2>&1; then
        exiftool "${FPATH}" | eval "$PAGER"
    else
        return
    fi
    exit 0
}

# - HANDLE AUDIO --------------------------------------------------------------
handle_audio() {
    if type mocp >/dev/null 2>&1 && type mocq >/dev/null 2>&1; then
        mocq "${FPATH}" "opener" >/dev/null 2>&1
    elif type mpv >/dev/null 2>&1; then
        mpv "${FPATH}" >/dev/null 2>&1 &
    elif type media_client >/dev/null 2>&1; then
        media_client play "${FPATH}" >/dev/null 2>&1 &
    elif type mediainfo >/dev/null 2>&1; then
        mediainfo "${FPATH}" | eval "$PAGER"
    elif type exiftool >/dev/null 2>&1; then
        exiftool "${FPATH}"| eval "$PAGER"
    else
        return
    fi
    exit 0
}

# - HANDLE AUDIO --------------------------------------------------------------
handle_video() {
    if [ "$GUI" -ne 0 ]; then
        if is_mac; then
            nohup open "${FPATH}" >/dev/null 2>&1 &
        elif type smplayer >/dev/null 2>&1; then
            nohup smplayer "${FPATH}" >/dev/null 2>&1 &
        elif type mpv >/dev/null 2>&1; then
            nohup mpv "${FPATH}" >/dev/null 2>&1 &
        else
            return
        fi
    elif type ffmpegthumbnailer >/dev/null 2>&1; then
        # Thumbnail
        [ -d "${IMAGE_CACHE_PATH}" ] || mkdir "${IMAGE_CACHE_PATH}"
        ffmpegthumbnailer -i "${FPATH}" -o "${IMAGE_CACHE_PATH}/${FNAME}.jpg" -s 0
        viu -n "${IMAGE_CACHE_PATH}/${FNAME}.jpg" | eval "$PAGER"
    elif type mediainfo >/dev/null 2>&1; then
        mediainfo "${FPATH}" | eval "$PAGER"
    elif type exiftool >/dev/null 2>&1; then
        exiftool "${FPATH}"| eval "$PAGER"
    else
        return
    fi
    exit 0
}

# - MAIN FUNCTION -------------------------------------------------------------
handle_extension() {
    case "${ext}" in
        ## Archive
        a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|\
        rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)
            if type atool >/dev/null 2>&1; then
                atool --list -- "${FPATH}" | eval "$PAGER"
                exit 0
            elif type bsdtar >/dev/null 2>&1; then
                bsdtar --list --file "${FPATH}" | eval "$PAGER"
                exit 0
            fi
            exit 1;;
        rar)
            if type unrar >/dev/null 2>&1; then
                ## Avoid password prompt by providing empty password
                unrar lt -p- -- "${FPATH}" | eval "$PAGER"
            fi
            exit 1;;
        7z)
            if type 7z >/dev/null 2>&1; then
                ## Avoid password prompt by providing empty password
                7z l -p -- "${FPATH}" | eval "$PAGER"
                exit 0
            fi
            exit 1;;

        ## PDF
        pdf)
            handle_pdf
            exit 1;;

        ## Audio
        aac|flac|m4a|mid|midi|mpa|mp2|mp3|ogg|wav|wma)
            handle_audio
            exit 1;;

        ## Video
        avi|mkv|mp4)
            handle_video
            exit 1;;

        ## Log files
        log)
            "$EDITOR" "${FPATH}"
            exit 0;;

        ## BitTorrent
        torrent)
            if type rtorrent >/dev/null 2>&1; then
                rtorrent "${FPATH}"
                exit 0
            elif type transmission-show >/dev/null 2>&1; then
                transmission-show -- "${FPATH}"
                exit 0
            fi
            exit 1;;

        ## OpenDocument
        odt|ods|odp|sxw)
            if type odt2txt >/dev/null 2>&1; then
                ## Preview as text conversion
                odt2txt "${FPATH}" | eval "$PAGER"
                exit 0
            fi
            exit 1;;

        ## Markdown
        md)
            if type glow >/dev/null 2>&1; then
                glow -sdark "${FPATH}" | eval "$PAGER"
                exit 0
            elif type lowdown >/dev/null 2>&1; then
                lowdown -Tterm "${FPATH}" | eval "$PAGER"
                exit 0
            fi
            ;;

        ## HTML
        htm|html|xhtml)
            ## Preview as text conversion
            if type w3m >/dev/null 2>&1; then
                w3m -dump "${FPATH}" | eval "$PAGER"
                exit 0
            elif type lynx >/dev/null 2>&1; then
                lynx -dump -- "${FPATH}" | eval "$PAGER"
                exit 0
            elif type elinks >/dev/null 2>&1; then
                elinks -dump "${FPATH}" | eval "$PAGER"
                exit 0
            fi
            ;;

        ## JSON
        json)
            if type jq >/dev/null 2>&1; then
                jq --color-output . "${FPATH}" | eval "$PAGER"
                exit 0
            elif type python >/dev/null 2>&1; then
                python -m json.tool -- "${FPATH}" | eval "$PAGER"
                exit 0
            fi
            ;;

        ## STL
        stl)
			fstl "${FPATH}"
            ;;

		## GMSH
        geo)
			gmsh "${FPATH}"
            ;;
    esac
}

# sets the variable abs_target, this should be faster than calling printf
abspath() {
    case "$1" in
        /*) abs_target="$1";;
        *)  abs_target="$PWD/$1";;
    esac
}

# storing the result to a tmp file is faster than calling listimages twice
listimages() {
    find -L "///${1%/*}" -maxdepth 1 -type f -print0 |
        grep -izZE '\.(jpe?g|png|gif|webp|tiff|bmp|ico|svg)$' |
        sort -z | tee "$tmp"
}

load_dir() {
    abspath "$2"
    tmp="${TMPDIR:-/tmp}/nuke_$$"
    trap 'rm -f $tmp' EXIT
    count="$(listimages "$abs_target" | grep -a -m 1 -ZznF "$abs_target" | cut -d: -f1)"

    if [ -n "$count" ]; then
        if [ "$GUI" -ne 0 ]; then
            xargs -0 nohup "$1" -n "$count" -- < "$tmp"
        else
            xargs -0 "$1" -n "$count" -- < "$tmp"
        fi
    else
        shift
        "$1" -- "$@" # fallback
    fi
}

handle_multimedia() {
    ## Size of the preview if there are multiple options or it has to be
    ## rendered from vector graphics. If the conversion program allows
    ## specifying only one dimension while keeping the aspect ratio, the width
    ## will be used.
    # local DEFAULT_SIZE="1920x1080"

    mimetype="${1}"
    case "${mimetype}" in
        ## SVG
        # image/svg+xml|image/svg)
        #     convert -- "${FPATH}" "${IMAGE_CACHE_PATH}" && exit 6
        #     exit 1;;

        ## DjVu
        # image/vnd.djvu)
        #     ddjvu -format=tiff -quality=90 -page=1 -size="${DEFAULT_SIZE}" \
        #           - "${IMAGE_CACHE_PATH}" < "${FPATH}" \
        #           && exit 6 || exit 1;;

        ## Image
        image/*)
            if [ "$GUI" -ne 0 ]; then
                if is_mac; then
                    nohup open "${FPATH}" >/dev/null 2>&1 &
                    exit 0
                elif type imvr >/dev/null 2>&1; then
                    load_dir imvr "${FPATH}" >/dev/null 2>&1 &
                    exit 0
                elif type sxiv >/dev/null 2>&1; then
                    load_dir sxiv "${FPATH}" >/dev/null 2>&1 &
                    exit 0
                elif type nsxiv >/dev/null 2>&1; then
                    load_dir nsxiv "${FPATH}" >/dev/null 2>&1 &
                    exit 0
                fi
            elif type viu >/dev/null 2>&1; then
                viu -n "${FPATH}" | eval "$PAGER"
                exit 0
            elif type img2txt >/dev/null 2>&1; then
                img2txt --gamma=0.6 -- "${FPATH}" | eval "$PAGER"
                exit 0
            elif type exiftool >/dev/null 2>&1; then
                exiftool "${FPATH}" | eval "$PAGER"
                exit 0
            fi
            # local orientation
            # orientation="$( identify -format '%[EXIF:Orientation]\n' -- "${FPATH}" )"
            ## If orientation data is present and the image actually
            ## needs rotating ("1" means no rotation)...
            # if [[ -n "$orientation" && "$orientation" != 1 ]]; then
                ## ...auto-rotate the image according to the EXIF data.
                # convert -- "${FPATH}" -auto-orient "${IMAGE_CACHE_PATH}" && exit 6
            # fi

            ## `w3mimgdisplay` will be called for all images (unless overridden
            ## as above), but might fail for unsupported types.
            exit 7;;

        ## PDF
        application/pdf)
            handle_pdf
            exit 1;;

        ## Audio
        audio/*)
            handle_audio
            exit 1;;

        ## Video
        video/*)
            handle_video
            exit 1;;

        #     pdftoppm -f 1 -l 1 \
        #              -scale-to-x "${DEFAULT_SIZE%x*}" \
        #              -scale-to-y -1 \
        #              -singlefile \
        #              -jpeg -tiffcompression jpeg \
        #              -- "${FPATH}" "${IMAGE_CACHE_PATH%.*}" \
        #         && exit 6 || exit 1;;


        ## ePub, MOBI, FB2 (using Calibre)
        # application/epub+zip|application/x-mobipocket-ebook|\
        # application/x-fictionbook+xml)
        #     # ePub (using https://github.com/marianosimone/epub-thumbnailer)
        #     epub-thumbnailer "${FPATH}" "${IMAGE_CACHE_PATH}" \
        #         "${DEFAULT_SIZE%x*}" && exit 6
        #     ebook-meta --get-cover="${IMAGE_CACHE_PATH}" -- "${FPATH}" \
        #         >/dev/null && exit 6
        #     exit 1;;

        ## Font
        # application/font*|application/*opentype)
        #     preview_png="/tmp/$(basename "${IMAGE_CACHE_PATH%.*}").png"
        #     if fontimage -o "${preview_png}" \
        #                  --pixelsize "120" \
        #                  --fontname \
        #                  --pixelsize "80" \
        #                  --text "  ABCDEFGHIJKLMNOPQRSTUVWXYZ  " \
        #                  --text "  abcdefghijklmnopqrstuvwxyz  " \
        #                  --text "  0123456789.:,;(*!?') ff fl fi ffi ffl  " \
        #                  --text "  The quick brown fox jumps over the lazy dog.  " \
        #                  "${FPATH}";
        #     then
        #         convert -- "${preview_png}" "${IMAGE_CACHE_PATH}" \
        #             && rm "${preview_png}" \
        #             && exit 6
        #     else
        #         exit 1
        #     fi
        #     ;;

        ## Preview archives using the first image inside.
        ## (Very useful for comic book collections for example.)
        # application/zip|application/x-rar|application/x-7z-compressed|\
        #     application/x-xz|application/x-bzip2|application/x-gzip|application/x-tar)
        #     local fn=""; local fe=""
        #     local zip=""; local rar=""; local tar=""; local bsd=""
        #     case "${mimetype}" in
        #         application/zip) zip=1 ;;
        #         application/x-rar) rar=1 ;;
        #         application/x-7z-compressed) ;;
        #         *) tar=1 ;;
        #     esac
        #     { [ "$tar" ] && fn=$(tar --list --file "${FPATH}"); } || \
        #     { fn=$(bsdtar --list --file "${FPATH}") && bsd=1 && tar=""; } || \
        #     { [ "$rar" ] && fn=$(unrar lb -p- -- "${FPATH}"); } || \
        #     { [ "$zip" ] && fn=$(zipinfo -1 -- "${FPATH}"); } || return
        #
        #     fn=$(echo "$fn" | python -c "import sys; import mimetypes as m; \
        #             [ print(l, end='') for l in sys.stdin if \
        #               (m.guess_type(l[:-1])[0] or '').startswith('image/') ]" |\
        #         sort -V | head -n 1)
        #     [ "$fn" = "" ] && return
        #     [ "$bsd" ] && fn=$(printf '%b' "$fn")
        #
        #     [ "$tar" ] && tar --extract --to-stdout \
        #         --file "${FPATH}" -- "$fn" > "${IMAGE_CACHE_PATH}" && exit 6
        #     fe=$(echo -n "$fn" | sed 's/[][*?\]/\\\0/g')
        #     [ "$bsd" ] && bsdtar --extract --to-stdout \
        #         --file "${FPATH}" -- "$fe" > "${IMAGE_CACHE_PATH}" && exit 6
        #     [ "$bsd" ] || [ "$tar" ] && rm -- "${IMAGE_CACHE_PATH}"
        #     [ "$rar" ] && unrar p -p- -inul -- "${FPATH}" "$fn" > \
        #         "${IMAGE_CACHE_PATH}" && exit 6
        #     [ "$zip" ] && unzip -pP "" -- "${FPATH}" "$fe" > \
        #         "${IMAGE_CACHE_PATH}" && exit 6
        #     [ "$rar" ] || [ "$zip" ] && rm -- "${IMAGE_CACHE_PATH}"
        #     ;;
    esac
}

handle_mime() {
    mimetype="${1}"
    case "${mimetype}" in
        ## Manpages
        text/troff)
            man -l "${FPATH}"
            exit 0;;

        ## Text
        text/* | */xml)
            "$EDITOR" "${FPATH}"
            exit 0;;
            ## Syntax highlight
            # if [[ "$( stat --printf='%s' -- "${FPATH}" )" -gt "${HIGHLIGHT_SIZE_MAX}" ]]; then
            #     exit 2
            # fi
            # if [[ "$( tput colors )" -ge 256 ]]; then
            #     local pygmentize_format='terminal256'
            #     local highlight_format='xterm256'
            # else
            #     local pygmentize_format='terminal'
            #     local highlight_format='ansi'
            # fi
            # env HIGHLIGHT_OPTIONS="${HIGHLIGHT_OPTIONS}" highlight \
            #     --out-format="${highlight_format}" \
            #     --force -- "${FPATH}" && exit 5
            # pygmentize -f "${pygmentize_format}" -O "style=${PYGMENTIZE_STYLE}"\
            #     -- "${FPATH}" && exit 5
            # exit 2;;

        ## DjVu
        image/vnd.djvu)
            if type djvutxt >/dev/null 2>&1; then
                ## Preview as text conversion (requires djvulibre)
                djvutxt "${FPATH}" | eval "$PAGER"
                exit 0
            elif type exiftool >/dev/null 2>&1; then
                exiftool "${FPATH}" | eval "$PAGER"
                exit 0
            fi
            exit 1;;
    esac
}

handle_fallback() {
    if [ "$GUI" -ne 0 ]; then
        if type xdg-open >/dev/null 2>&1; then
            nohup xdg-open "${FPATH}" >/dev/null 2>&1 &
            exit 0
        elif type open >/dev/null 2>&1; then
            nohup open "${FPATH}" >/dev/null 2>&1 &
            exit 0
        fi
    fi

    echo '----- File details -----' && file --dereference --brief -- "${FPATH}"
    exit 1
}

handle_blocked() {
    case "${MIMETYPE}" in
        application/x-sharedlib)
            exit 0;;

        application/x-shared-library-la)
            exit 0;;

        application/x-executable)
            exit 0;;

        application/x-shellscript)
            exit 0;;

        application/octet-stream)
            exit 0;;
    esac
}

handle_bin() {
    case "${MIMETYPE}" in
        application/x-executable|application/x-shellscript)
        clear
        echo '-------- Executable File --------' && file --dereference --brief -- "${FPATH}"
        printf "Run executable (y/N/'a'rgs)? "
        read -r answer
        case "$answer" in
            [Yy]* ) exec "${FPATH}";;
            [Aa]* )
                printf "args: "
                read -r args
                exec "${FPATH}" "$args";;
            [Nn]* ) exit;;
        esac
    esac
}

MIMETYPE="$( file -bL --mime-type -- "${FPATH}" )"
handle_extension
handle_multimedia "${MIMETYPE}"
handle_mime "${MIMETYPE}"
[ "$BIN" -ne 0 ] && [ -x "${FPATH}" ] && handle_bin
handle_blocked "${MIMETYPE}"
handle_fallback

exit 1
