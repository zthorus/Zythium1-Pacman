! Pac-Man game
! By S. Morel, Zthorus-Labs, 2020

! Date         Action
! ---          ------
! 2020-01-23   Created

! To-do: * Various fruits for different levels.
!        * Re-structuration of code (cuurently it's a mess)

! Note: for use on ZTH1 computer implemented on Maximator, wire joystick as:
!     up = N = il[0] = J16 = D2
!   down = S = il[1] = H15 = D3
!   left = W = il[2] = H16 = D4
!  right = E = il[3] = G15 = D5
! common = GND

org x0000

! Sprite control addresses
! Pacman= sprite #0, ghosts= sprites #4 to #7 (easier for color management)
@pm_xy=x1818       ! coordinates of Pacman
@pm_sprite=x182a   ! bitmap of Pacman
@gh_xy=x181c       ! coordinates of 1st ghost
@gh_sprite=x184a   ! bitmap of 1st ghost 
@gh_color=x1826    ! color of 1st ghost

! Variables

@xx=x1aea       ! cell coordinates
@yy=x1aeb
@xp=x1aec        ! Pacman coordinates (in pix)
@yp=x1aed
@xpg=x1aef       ! Pacman coordinates (in cell coord.)
@ypg=x1af0
@dirp=x1af1      ! Pacman direction (0=N, 1=E, 2=S, 3=W)
@dxp=x1af2       ! Pacman motion vector
@dyp=x1af3
@motp=x1af4      ! =1 if Pacman is in motion
@notoncell=x1af5 ! =1 if Pacman not on cell (moving) 
@countp=x1af6    ! Pacman counter (before moving 1 pix)
@countpm=x1af7   ! max value of Pacman counter (define speed)
@joy=x1af8       ! joystick position 
@score=x1af9     ! score of the game
@rem_pel=x1afa   ! remaining pellets (and vitamins)
@ii=x1afb        ! general purpose index
@nn=x1afc        ! general purpose variable
@dig=x1afd       ! digit of score to be printed

! Variables for ghosts : we define names for the 1st ghost and pointers
! to address all the ghosts

@p_state=x1afe
@state=x1aff    ! state (scatter, chase, frightened, eaten)
@p_xg=x1b03
@xg=x1b04       ! coordinates (in pix)
@p_yg=x1b08
@yg=x1b09
@p_xgg=x1b0d   
@xgg=x1b0e      ! coordinates (in cell coord.)
@p_ygg=x1b12
@ygg=x1b13
@p_dirg=x1b17   ! direction (0=N, 1=E, 2=S, 3=W)
@dirg=x1b18
@p_dxg=x1b1c
@dxg=x1b1d      ! motion vector
@p_dyg=x1b21
@dyg=x1b22
@p_gnocell=x1b26
@gnocell=x1b27    ! =1 if ghost not on cell
@p_statecnt=x1b3b
@statecnt=x1b3c    ! counter of state duration
@p_countg=x1b40
@countg=x1b41      ! counter (before moving 1 pix)

@countgm=x1b45          ! max value of ghost counter (define speed)
@forbidden_dir=x1b46    ! forbidden direction (to avoid U-turns)
@tgx=x1b48              ! target coordinates
@tgy=x1b49
@dist=x1b4a             ! distance to target
@min_dist=x1b4b         ! minimum distance to target found
@scatterd=x1b4c         ! duration (in state-cntr cycles) of scatter state
@chased=x1b4d           ! duration (in state-cntr cycles) of chase state 
@frightd=x1b4e          ! duration (in state-cntr cycles) of frightened state
@p_gh_xy=x1b4f          ! pointer to sprite coordinates for ghosts
@xnc=x1b50              ! coordinates of neighboring cell 
@ync=x1b51
@p_ghsprt=x1b52         ! pointer to ghost sprite bitmap            
@p_ghcolor=x1b53        ! pointer to ghost color

! Other variables (forgotten to be declared before)
@fruitcnt=x1bfa         ! counter of fruit presence
@gstatecnt=x1bfb        ! global ghost state counter
@pseudorand=x1bfc       ! pseudo-random number
@jj=x1bfd               ! variable for iterations
@level=x1bfe            ! level in game
@lives=x1bff            ! number of lives

! Variables used by display-character routine
@dc_xy=x1c00            ! high-byte: y (0 to 15), low-byte: x (0 to 23)
@dc_char =x1c02         ! character to display
@dc_p_vram=x1c01        ! VRAM pointer
@dc_p_bmp=x1c03         ! character bitmap pointer
@dc_c1=x1c04            ! counters
@dc_c2=x1c05
@dc_c3=x1c06
@dc_colors=x1c07        !  high-byte: ink, low-byte: paper
! Variables used by display-score routine
@ds_n=x1c08             !  remainder of score
@ds_i=x1c09             !  index of digit 


! Beginning of program
! skip instruction words reserved for interrupt vector #1
jump @begin

org x0010
@begin

! Draw (empty) maze

entr @dc_colors
entr x0100
stw ; nop
clh ; cll
entr @xx
swp ; stw 
entr @yy
swp ; stw 
@dm_loop
entr @xx
gtw ; nop
entr @yy
gtw ; nop
call @get_cell
entr @dc_char
swp ; stw
entr @dc_xy
entr @yy
gtw ; swa
sth ; drp
entr @xx 
gtw ; stl 
call @disp_ch
entr @xx
dup ; gtw
inc ; stw
comp x0013
jpnz @dm_loop
entr @xx      ! move to next line
entr x0000
stw ; nop
entr @yy
dup ; gtw
inc ; stw
comp x0010
jpnz @dm_loop


! Initialize variables at beginning of game

entr @countpm
entr x0032 
stw ; nop
entr @score
entr x0000
stw ; nop
entr @lives
entr x0003
stw ; nop
entr @level
entr x0000
stw ; nop
entr @countgm
entr x0040   
stw ; nop
entr @scatterd
entr x0100
stw ; nop
entr @chased
entr  x0300
stw ; nop
entr @frightd
entr x00c0
stw ; nop
entr @pseudorand
entr xc5e3       ! seed (=any number)
stw ; nop
entr @dc_char    ! mark lives
entr x0057       ! pacman char
stw ; nop
entr @dc_colors
entr x0200
stw ; nop
entr @dc_xy
entr x0e14
stw ; nop
call @disp_ch
entr @dc_xy
dup ; gtw
inc ; stw
call @disp_ch
entr @dc_xy
dup ; gtw
inc ; stw
call @disp_ch


@start_level

! Fill maze with pellets and vitamins

entr x0001
entr @xx
swp ; stw 
entr @yy
swp ; stw 
@fm_loop
entr @xx
gtw ; nop
entr @yy
gtw ; nop
call @get_cell
comp x0020
jmpz @fm_pel
comp x0023   ! if pellet already in maze (left by previous game)
jmpz @fm_pel  ! then re-draw it 
comp x0021
jmpz @fm_vit
comp x0024    ! if vitamin already in maze (left by previous game)
jmpz @fm_vit  ! then re-draw it 
jump @fm_jp2
@fm_pel
drp ; nop
entr @xx
gtw ; rrw    ! check parity of x
drp ; nop    ! now A=addres of cell
jmpc @fm_odd1
psh x23      ! put pellet in cell (x even) 
sth ; nop
jump @fm_prp
@fm_odd1
psl x23      ! put pellet in cell (x odd)
stl ; nop
@fm_prp
entr @dc_colors ! prepare to draw pellet (character and color)
entr x0900
stw ; nop
entr @dc_char
entr x0023
stw ; nop
jump @fm_jp1
@fm_vit
drp ; nop
entr @xx
gtw ; rrw    ! check parity of x
drp ; nop
jmpc @fm_odd2
psh x24      ! put vitamin in cell (x even) 
sth ; nop
jump @fm_prv
@fm_odd2
psl x24      ! put vitamin in cell (x odd)
stl ; nop
@fm_prv
entr @dc_colors ! prepare to draw vitamin (character and color)
entr x0800
stw ; nop
entr @dc_char
entr x0024
stw ; nop
@fm_jp1
entr @dc_xy ! set (x,y) for printing 
entr @yy
gtw ; swa
sth ; drp
entr @xx 
gtw ; stl 
call @disp_ch
@fm_jp2
entr @xx
dup ; gtw
inc ; stw
comp x0012
jpnz @fm_loop
entr @xx      ! move to next line
entr x0001
stw ; nop
entr @yy
dup ; gtw
inc ; stw
comp x000f
jpnz @fm_loop

entr @rem_pel
entr x0096     ! total number of pellets + vitamins (to be checked)
stw ; nop

@start_life

! Initialize variables

! Pacman variables
entr @xpg
entr x0009
stw ; nop
entr @ypg
entr x000A
stw ; nop
entr @xp
entr x0048
stw ; nop
entr @yp
entr x0050
stw ; nop
entr @dirp
entr x0003
stw ; nop
entr @dxp
entr xffff
stw ; nop
entr @dyp
entr x0000
stw ; nop
entr @countp
entr @countpm
gtw ; stw
entr @notoncell
entr x0001
stw ; nop
entr @motp
entr x0001
stw ; nop
entr @pm_xy
entr xd048
stw ; nop
entr @bpmbmp
entr @pm_sprite
call @copy_sprite
entr @fruitcnt
entr x0000
stw ; nop
! Ghost variables
entr @state
entr x0000    ! 0= scatter 
stw ; swp
inc ; swp
stw ; swp
inc ; swp
stw ; swp
inc ; swp
stw ; nop
entr @statecnt
entr @scatterd
gtw ; stw
swp ; inc
swp ; stw
swp ; inc
swp ; stw
swp ; inc
swp ; stw
entr @gnocell
entr x0001
stw ; swp
inc ; swp
stw ; swp
inc ; swp
stw ; swp
inc ; swp
stw ; nop
entr @gh_color   ! trick: order of colors in LUT (3 to 6) = order of ghosts
entr x0003
stl ; inc
swp ; inc
swp ; stl
inc ; swp
inc ; swp
stl ; inc
swp ; inc
swp ; stl
entr @ygg
entr x0006
stw ; swp
inc ; swp
stw ; swp
inc ; swp
stw ; swp
inc ; swp
stw ; nop
entr @xgg
entr x0008
stw ; inc
swp ; inc
swp ; stw
swp ; inc
swp ; stw   ! ghosts #1 and #2 start from same cell 
inc ; swp
inc ; swp
stw ; nop
entr @yg
entr x0030
stw ; swp
inc ; swp
stw ; swp
inc ; swp
stw ; swp
inc ; swp
stw ; nop
entr @xg
entr x0040 
stw ; drp
inc ; nop 
entr x0048
stw ; drp
inc ; nop
entr x0048
stw ; drp
inc ; nop
entr x0050
stw ; nop
entr @dirg
entr x0003 
stw ; swp
inc ; swp 
stw ; drp 
inc ; nop 
entr x0001
stw ; swp
inc; swp 
stw ; nop
entr @dxg
entr xffff
stw ; swp
inc; swp 
stw ; drp
inc ; nop 
entr x0001
stw ; swp
inc ; swp 
stw ; nop
entr @dyg
entr x0000
stw ; swp
inc ; swp
stw ; swp
inc ; swp
stw ; swp
inc ; swp
stw ; nop
entr @countg
entr @countgm
gtw ; stw
swp ; inc
swp ; stw
swp ; inc
swp ; stw
swp ; inc
swp ; stw
entr @nghbmp
entr @gh_sprite
call @copy_sprite
entr @nghbmp
entr @gh_sprite
entr x0008
add ; swp
drp ; nop
call @copy_sprite
entr @nghbmp
entr @gh_sprite
entr x0010
add ; swp
drp ; nop
call @copy_sprite
entr @nghbmp
entr @gh_sprite
entr x0018
add ; swp
drp ; nop
call @copy_sprite
entr @gstatecnt
entr x0000
stw ; nop
entr @gh_xy
entr xb040
stw ; drp 
inc ; nop
entr xb048
stw ; swp 
inc ; swp
stw ; drp
inc ; nop
entr xb050
stw ; nop
entr x1000   ! wait ~ 4 s
call @wait
 

@main_loop

! Manage Pacman motion

entr @countp
gtw ; nop
comp x0000
jpnz @pm_deccount
entr @countp  ! restore Pacman motion counter
entr @countpm
gtw ; stw 
entr @motp
gtw ; rrw ! fast way to compare to 1 
jpnc @pm_chdir ! Pacman is stuck, see if joystick action can move it
entr @notoncell
gtw ; nop
comp x0000
jmpz @pm_oncell ! Pacman has arrived right on cell

entr @xp     ! xp <= xp + dxp
dup ; gtw 
entr @dxp
gtw ; add
swp ; drp
stw ; nop 
entr @yp     ! yp <= yp + dyp
dup ; gtw 
entr @dyp
gtw ; add
swp ; drp
stw ; nop 

! display animated PacMan (nibbling) 
entr @dirp ! select x or x depending on direction
gtw ; nop
comp x0000
jpnz @pm_s1
entr @yp
jump @pm_s4
@pm_s1
comp x0001
jpnz @pm_s2
entr @xp
jump @pm_s4
@pm_s2
comp x0002
jpnz @pm_s3
entr @yp
jump @pm_s4
@pm_s3
entr @xp
@pm_s4
dup ; drp  ! fix pb of zth1: gtw not working right after jump
gtw ; nop  ! calculate 4*(dir*4 + (x | y)%4)
entr x0003
and ; swp
drp ; nop
entr @dirp  
gtw ; ccf
rlw ; rlw
add ; ccf
rlw ; rlw
entr @pm_phase
add ; nop
entr @pm_sprite
call @copy_sprite  ! copy Pacman bitmap as function of direction and phase

entr x8000         ! set Pacman sprite coordinates
entr @yp
gtw ; swa
orr ; nop          ! set sprite active flag
entr @xp
gtw ; orr
entr @pm_xy
swp ; stw

call @get_joy     ! check if U-turn wanted
comp x0000
jpnz @pm_u1
entr @dirp
gtw ; nop
comp x0002
jpnz @pm_chkoncell 
entr @dirp
entr x0000
stw ; nop
entr @dyp
entr xffff
stw ; nop
jump @pm_chkoncell
@pm_u1
comp x0001
jpnz @pm_u2
entr @dirp
gtw ; nop
comp x0003
jpnz @pm_chkoncell
entr @dirp
entr x0001
stw ; nop
entr @dxp
entr x0001
stw ; nop
jump @pm_chkoncell
@pm_u2
comp x0002
jpnz @pm_u3
entr @dirp
gtw ; nop
comp x0000
jpnz @pm_chkoncell
entr @dirp
entr x0002
stw ; nop
entr @dyp
entr x0001
stw ; nop
jump @pm_chkoncell
@pm_u3
comp x0003
jpnz @pm_chkoncell
entr @dirp
gtw ; nop
comp x0001
jpnz @pm_chkoncell
entr @dirp
entr x0003
stw ; nop
entr @dxp
entr xffff
stw ; nop

@pm_chkoncell
entr x0007  ! check if Pacman right on cell (if all 3 LSBs of x and y are 0)
entr @xp
gtw ; and
entr x0007
entr @yp
gtw ; and
swp ; drp
orr ; nop
entr @notoncell
swp ; stw

jump @pm_watchenv

@pm_oncell    ! action to take when Pacman has arrived on cell

entr @xpg   ! update cell coordinates  
entr @xp    ! xpg = xp /8 ; ypg = yp /8
gtw ; ccf
rrw ; ccf 
rrw ; ccf
rrw ; stw
entr @ypg
entr @yp
gtw ; ccf
rrw ; ccf 
rrw ; ccf
rrw ; stw

entr @dc_colors ! erase anything (pellet, vitamin) where Pacman is now
entr x0900
stw ; nop
entr @dc_char  
!entr x0022
entr x0020
stw ; nop
entr @dc_xy ! set (x,y) for printing 
entr @ypg
gtw ; swa
sth ; drp
entr @xpg 
gtw ; stl 
call @disp_ch

entr @fruitcnt    ! check if Pacman has eaten fruit
gtw ; nop
comp x0000
jmpz @pm_tunnel
entr @xpg         ! check if Pacman on fruit's cell
gtw ; nop
comp x0009
jpnz @pm_tunnel
entr @ypg
gtw ; nop
comp x000a
jpnz @pm_tunnel
entr @fruitcnt
entr x0000
stw ; nop
entr @score
dup ; gtw
entr x0064  ! + 100 pts
add ; swp
drp ; stw

@pm_tunnel
entr @ypg   ! check if Pacman enters tunnel
gtw ; nop
comp x0006
jpnz @pm_pelvit
entr @xpg
gtw ; nop
comp x0000
jpnz @pm_tun
entr @xpg        ! entering from W side
entr x0012       ! => teleport Pacman to E side
stw ; nop
entr @xp
entr x0090
stw ; nop
jump @pm_rst_step
@pm_tun
comp x0012
jpnz @pm_pelvit
entr @xpg       ! entering from E side
entr x0000      ! => teleport Pacman to W side
stw ; nop
entr @xp
swp ; stw
jump @pm_rst_step

@pm_pelvit
entr @xpg   ! check if pellet or vitamin eaten (tbw)
gtw ; nop
entr @ypg
gtw ; nop
call @get_cell
comp x0023
jmpz @pm_pel
comp x0024
jmpz @pm_vit
jump @pm_chwl
@pm_pel
ldh x20      ! replace pellet by space1 in maze
ldl x00
entr @xpg
gtw ; rrw    ! check parity of x
drp ; nop
jmpc @pm_odd1
sth ; nop 
jump @pm_pelscore
@pm_odd1
swa ; stl
@pm_pelscore ! increase score
entr @score
dup ; gtw
inc ; stw
entr @rem_pel
dup ; gtw
dec ; stw
jump @pm_chwl
@pm_vit
ldh x21       ! replace vitamin by space2 in maze
ldl x00
entr @xpg
gtw ; rrw    ! check parity of x
drp ; nop
jmpc @pm_odd2
sth ;  nop 
jump @pm_vitscore
@pm_odd2
swa ; stl
@pm_vitscore  ! increase score
entr @score
dup ; gtw
entr x000A
add ; swp
drp ; stw
entr @rem_pel
dup ; gtw
dec ; stw
entr @p_state
entr @state  ! turn ghosts in frightened mode (tbw)
stw ; nop
entr @p_ghsprt
entr @gh_sprite
stw ; nop
entr @p_ghcolor
entr @gh_color
stw ; nop
entr @ii
entr x0000
stw ; nop
@pm_sf1
entr @p_state
gtw ; dup
gtw ; nop
comp x0003   ! if ghost already eaten, do not turn it to frightened
jmpz @pm_sf2
ldl x02      ! set to frightened
stw ; nop
entr @fghbmp   ! make ghosts appear frightened
entr @p_ghsprt
gtw ; nop
call @copy_sprite
entr @p_ghcolor
gtw ; nop
entr x0007
stl ; nop
@pm_sf2
entr @p_state      ! increment the ponters
dup ; gtw
inc ; stw
entr @p_ghcolor
dup ; gtw
inc ; stw
entr @p_ghsprt
dup ; gtw
entr x0008
add ; swp
drp ; stw
entr @ii
dup ; gtw
inc ; stw
comp x0004
jpnz @pm_sf1
entr @gstatecnt    ! set global ghost-state counter     
entr @frightd
gtw ; stw

@pm_chwl
entr @dirp ! check if wall ahead
gtw ; nop
comp x0000
jpnz @pm_cwe
entr @xpg       ! if direction=N
gtw ; nop
entr @ypg
gtw ; dec
jump @pm_chkwl
@pm_cwe
comp x0001 
jpnz @pm_cws
entr @xpg      ! if direction=E
gtw ; inc
entr @ypg
gtw ; nop
jump @pm_chkwl
@pm_cws
comp x0002 
jpnz @pm_cww
entr @xpg      ! if direction=S
gtw ; nop 
entr @ypg
gtw ; inc 
jump @pm_chkwl
@pm_cww
entr @xpg      ! if direction=W
gtw ; dec 
entr @ypg
gtw ; nop 
@pm_chkwl
call @get_cell
comp x0039     ! if char in cell > '9' => wall
jpnc @pm_chdir
entr @motp     ! wall ahead => Pacman stopped 
entr x0000
stw ; nop

@pm_chdir  
call @get_joy   ! check if direction can be modified
comp x0000
jpnz @pm_jye
entr @xpg       ! if direction=N
gtw ; nop
entr @ypg
gtw ; dec
call @get_cell ! check if wall N
comp x0039
jmpc @pm_rst_step
entr @motp
entr x0001
stw ; nop
entr @dirp
entr x0000
stw ; nop
entr @dxp
entr x0000
stw ; nop
entr @dyp
entr xffff
stw ; nop
jump @pm_rst_step
@pm_jye
comp x0001
jpnz @pm_jys
entr @xpg       ! if direction=E
gtw ; inc 
entr @ypg
gtw ;nop 
call @get_cell ! check if wall E
comp x0039
jmpc @pm_rst_step
entr @motp
entr x0001
stw ; nop
entr @dirp
entr x0001
stw ; nop
entr @dxp
entr x0001
stw ; nop
entr @dyp
entr x0000
stw ; nop
jump @pm_rst_step
@pm_jys
comp x0002
jpnz @pm_jyw
entr @xpg       ! if direction=S
gtw ; nop 
entr @ypg
gtw ; inc 
call @get_cell ! check if wall S
comp x0039
jmpc @pm_rst_step
entr @motp
entr x0001
stw ; nop
entr @dirp
entr x0002
stw ; nop
entr @dxp
entr x0000
stw ; nop
entr @dyp
entr x0001
stw ; nop
jump @pm_rst_step
@pm_jyw
comp x0003
jpnz @pm_rst_step
entr @xpg       ! if direction=W
gtw ; dec 
entr @ypg
gtw ; nop 
call @get_cell ! check if wall W
comp x0039
jmpc @pm_rst_step
entr @motp
entr x0001
stw ; nop
entr @dirp
entr x0003
stw ; nop
entr @dxp
entr xffff
stw ; nop
entr @dyp
entr x0000
stw ; nop

@pm_rst_step  ! reset step (if motion possible)
entr @motp
gtw ; nop
comp x0001
jpnz @pm_watchenv
entr @notoncell ! already consider Pacman has left the cell
entr x0001
stw ; nop

! Environment watching (executed at each Pacman pixel move)
 
@pm_watchenv
entr @fruitcnt    ! check fruit status
dup ; gtw
comp x0000
jmpz @pm_dsc
dec ; stw         ! decrement counter
comp x0000        
jpnz @pm_dsc
entr @dc_xy       ! timeout => erase fruit
entr x0a09
stw ; nop 
entr @dc_char
entr x0020
stw ; nop
call @disp_ch
@pm_dsc
call @disp_score  ! show current score
entr @rem_pel     ! check nb of remaining pellets + vits
gtw ; nop
comp x0000
jmpz @pm_leveldone
comp x0060
jpnz @pm_frghost
entr @fruitcnt     ! if enough pellet eaten, show fruit
dup ; gtw
comp x0000
jpnz @pm_frghost
ldl xd0
stl ; nop          ! set fruit duration counter
entr @dc_xy
entr x0a09
stw ; nop
entr @dc_colors
entr x0300
stw ; nop
entr @dc_char
entr x002a
stw ; nop 
call @disp_ch      ! show fruit
jump @pm_frghost

@pm_leveldone
entr @ii         ! level completed => make maze blinking
entr x0000       ! (modify color#1 = color of walls from blue to white
stw ; nop        !  and from white to blue, repeat) 
@pm_lcl1
entr x1803
dup ; gtw
entr xff00
xor ; swp
drp ; stw
entr x1804
dup ; gtw
entr xff00
xor ; swp
drp ; stw
entr x0200   ! wait ~ 500 ms
call @wait
entr @ii
dup ; gtw
inc ; stw
comp x0006
jpnz @pm_lcl1
entr @level
dup ; gtw
inc ; stw
entr @countgm    ! make ghosts faster
dup ; gtw 
comp x0020
jpnc @pm_lcj1
entr x0008
swp ; sub
swp ; drp
stw ; nop
@pm_lcj1
entr @frightd
dup ; gtw
comp x0000
jmpz @pm_lcj2
entr x0020
swp ; sub
swp ; drp
stw ; nop
@pm_lcj2
entr @level
gtw ; nop
comp x0003
jpnz @start_level 
entr @chased    ! ghosts enter endless chase state from level 4
entr x7fff
stw ; nop
jump @start_level

@pm_frghost
entr @gstatecnt   ! watch timeout of ghost frightened state
dup ; gtw
comp x0000
jmpz @pm_collision      ! if already 0, don't care (not frightened)
comp x0018
jpnz @pm_wj1
entr @gh_color   !  ghosts about to be back to normal => change color  
entr x0008
stl ; swp
inc ; swp
stl ; swp
inc ; swp
stl ; swp
inc ; swp
stl ; nop   
drp ; drp
@pm_wj1 
dec ; stw
comp x0000
jpnz @pm_collision
entr @state
entr x0000        ! restore all ghosts in scatter mode 
stw ; swp
inc ; swp
stw ; swp
inc ; swp
stw ; swp
inc ; swp
stw ; nop
entr @statecnt
entr @scatterd
gtw ; stw
swp ; inc
swp ; stw
swp ; inc
swp ; stw
swp ; inc
swp ; stw
entr @gh_color   ! restore normal ghost colors
entr x0003
stl ; inc
swp ; inc
swp ; stl
inc ; swp
inc ; swp
stl ; inc
swp ; inc
swp ; stl
entr @nghbmp         ! restore normal ghost appearance
entr @gh_sprite
call @copy_sprite
entr @nghbmp
entr @gh_sprite
entr x0008
add ; swp
drp ; nop
call @copy_sprite
entr @nghbmp
entr @gh_sprite
entr x0010
add ; swp
drp ; nop
call @copy_sprite
entr @nghbmp
entr @gh_sprite
entr x0018
add ; swp
drp ; nop
call @copy_sprite

@pm_collision
entr x1824        ! check pacman vs ghost collision
gtl ; nop
entr x000f        ! pacman = sprite #0 => check lowest nibble
and ; swp
drp ; nop
comp x0000
jmpz @pm_end
entr @gstatecnt
gtw ; nop
comp x0000
jmpz @pm_dead     ! if pacman hit ghost and ghosts not frightened => dead
drp ; nop
dec ; dec
dec ; dec         ! ghost indx = sprite# -4
entr @ii          ! save index of ghost
swp ; stw
entr @state
add ; dup
gtw ; nop
comp x0003        ! if ghost already eaten, do not care
jmpz @pm_end 
drp ; nop
entr x0003        ! turn ghost in eaten state
stw ; drp
drp ; nop
entr @eghbmp
entr @ii
gtw ; ccf
rlw ; rlw
rlw ; nop        ! multiply index by 8 
entr @gh_sprite
add ; swp
drp ; nop
call @copy_sprite
entr @score       ! increase score 
dup ; gtw
entr x0064        ! +100 pts
add ; swp
drp ; stw
jump @pm_end
@pm_dead
entr @ii        ! Pacman death animation
entr x0000
stw ; nop
@pm_ddl1
entr @pm_phase
entr x0004
add ; swp
drp ; nop
entr @ii
gtw ; ccf
rlw ; rlw
rlw ; rlw
add ; swp
drp ; nop
entr @pm_sprite
call @copy_sprite
entr x0100   ! wait ~ 250 ms
call @wait
entr @ii
dup ; gtw
inc ; stw
comp x0004
jpnz @pm_ddl1
entr @dpmbmp
entr @pm_sprite
call @copy_sprite
entr x0100   ! wait ~ 250 ms
call @wait
entr @fruitcnt   ! erase fruit (if any)
entr x0000
stw ; nop
entr @dc_char
entr x0020
stw ; nop
entr @dc_xy
entr x0a09
stw ; nop
call @disp_ch
entr @dc_char    ! erase life mark
entr x0020
stw ; nop
entr @dc_xy
entr x0e13
entr @lives
gtw ; add
swp ; drp
stw ; nop
call @disp_ch 
entr @lives
dup ; gtw
dec ; stw       ! decrement number of lives
comp x0000
jmpz @game_over
jump @start_life

@pm_deccount ! decrement counter
entr @countp
dup ; gtw
dec ; stw

@pm_end ! end of Pacman motion part 

! Ghost motion (the big deal)

entr @p_state    ! initialize pointers to address of 1st ghost's variables
entr @state
stw ; nop
entr @p_xg
entr @xg
stw ; nop
entr @p_yg
entr @yg
stw ; nop
entr @p_xgg
entr @xgg
stw ; nop
entr @p_ygg
entr @ygg
stw ; nop
entr @p_dirg
entr @dirg
stw ; nop
entr @p_dxg
entr @dxg
stw ; nop
entr @p_dyg
entr @dyg
stw ; nop
entr @p_gnocell
entr @gnocell
stw ; nop
entr @p_countg
entr @countg
stw ; nop
entr @p_statecnt
entr @statecnt
stw ; nop
entr @p_gh_xy
entr @gh_xy
stw ; nop

entr @ii
entr x0000
stw ; nop

@gh_mainloop     ! for each ghost, do...

entr @p_countg
gtw ; gtw
comp x0000
jpnz @gh_deccount
entr @p_countg    ! restore ghost motion counter
gtw ; nop
entr @countgm
gtw ; nop 
entr @p_state
gtw ; gtw
comp x0002   ! if state = frightened, speed is divided by two
jmpz @gh_j1
comp x0003   ! if state = eaten, speed is multiply by 4
jmpz @gh_j23
drp ; stw
jump @gh_j2
@gh_j1
drp ; dup    ! multiply countgm by 2 in frightened state
add ; swp
drp ; stw
jump @gh_j2
@gh_j23
drp ; ccf    ! divide countgm by 4 in eaten state
rrw ; rrw
stw ; nop 
@gh_j2

entr @p_xg
gtw ; dup
gtw ; nop
entr @p_dxg
gtw ; gtw
add ; swp
drp ; stw     ! x_ghost = x_ghost + dx_ghost
entr @p_yg
gtw ; dup
gtw ; nop
entr @p_dyg
gtw ; gtw
add ; swp
drp ; stw     ! y_ghost = y_ghost + dy_ghost

entr @p_gh_xy  ! update sprite coordinates
gtw ; nop
entr x8000     ! set sprite activity flag to 1
entr @p_yg
gtw ; gtw
swa ; orr
swp ; drp
entr @p_xg
gtw ; gtw
orr ; swp
drp ; stw

entr @p_gnocell  ! check if ghost right on cell
gtw ; nop        ! if (x_ghost & 7) | (y_ghost & 7) != 0 
entr @p_xg
gtw ; gtw
entr x0007
and ; swp
drp ; nop
entr @p_yg
gtw ; gtw
entr x0007
and ; swp
drp ; orr
swp ; drp
stw ; nop 

jpnz @gh_statemach

@gh_oncell

entr @p_xgg    ! update coordinates of cell where ghost is now
gtw ; dup
gtw ; nop
entr @p_dxg
gtw ; gtw
add ; swp
drp ; stw     
entr @p_ygg
gtw ; dup
gtw ; nop
entr @p_dyg
gtw ; gtw
add ; swp
drp ; stw    

entr @p_ygg          ! check if ghost has entered tunnel
gtw ; gtw
comp x0006
jpnz @gh_algo
entr @p_xgg
gtw ; gtw
comp x0000
jpnz @gh_t1
entr @p_xgg         ! entrance W side  => teleport ghost to E side
gtw ; nop
entr x0012
stw ; nop
entr @p_xg
gtw ; nop
entr x0090
stw ; nop
jump @gh_statemach
@gh_t1
comp x0012
jpnz @gh_algo
entr @p_xgg         ! entrance E side => teleport ghost to W side
gtw ; nop
entr x0000
stw ; nop
entr @p_xg
gtw ; swp
stw ; nop
jump @gh_statemach

@gh_algo
entr @forbidden_dir   ! find out forbidden next direction (no U-turns allowed)
entr @p_dirg
gtw ; gtw
inc ; inc
entr x0003    ! forbidden dir = (direction + 2) % 4
and ; swp
drp ; stw
entr @p_state
gtw ; gtw
comp x0000
jpnz @gh_j3
entr @tgx        ! ghost in scatter state => target = scatter target
entr @tgscx      ! (scatter target depends on ghost identity)
entr @ii
gtw ; add 
swp ; drp 
gtw ; stw 
entr @tgy
entr @tgscy
entr @ii
gtw ; add 
swp ; drp 
gtw ; stw 
jump @gh_find_nextdir
@gh_j3
comp x0001
jpnz @gh_j21
entr @ii       ! ghost in chase state => target depends on ghost identity
gtw ; nop
comp x0000
jpnz @gh_jc1
entr @tgx      ! 1st ghost: target = Pacman
entr @xpg
gtw ; stw
entr @tgy
entr @ypg
gtw ; stw
jump @gh_find_nextdir
@gh_jc1
comp x0001
jpnz @gh_jc2
entr @tgx
entr @xpg      ! 2nd ghost: target = Pacman + 3 cells ahead
gtw ; nop
entr @dxp
gtw ; swp
add ; add
add ; swp
drp ; stw
entr @tgy
entr @ypg  
gtw ; nop
entr @dyp
gtw ; swp
add ; add
add ; swp
drp ; stw
jump @gh_find_nextdir
@gh_jc2
comp x0002
jpnz @gh_jc3
entr @p_xgg           
gtw ; gtw    ! 3rd ghost: if distance ghost-to-Pacman > 6 then
entr @xpg    !            target = Pacman, else target = scatter target
gtw ; nop
entr @p_ygg
gtw ; gtw
entr @ypg
gtw ; nop
call @calc_sqdist
comp x0024        ! 36 = 6^2
jpnc @gh_jc4
entr @tgx
entr @xpg
gtw ; stw
entr @tgy
entr @ypg
gtw ; stw
jump @gh_find_nextdir
@gh_jc4
entr @tgx
entr @tgscx
inc ; inc
gtw ; stw
entr @tgy
entr @tgscy
inc ; inc
gtw ; stw
jump @gh_find_nextdir
@gh_jc3
entr @tgx     ! 4th ghost: target = position 1st ghost + 2*(position
entr @xgg     ! Pacman +2 cells ahead - position 1st ghost)
gtw ; nop     ! = 2*(position Pacman +2 cells ahead) - position 1st ghost 
entr @dxp
gtw ; nop
entr @xpg
gtw ; add 
add ; swp
drp ; dup
add ; swp 
drp ; sub
swp ; drp
stw ; nop
entr @tgy     
entr @ygg     
gtw ; nop 
entr @dyp
gtw ; nop
entr @ypg
gtw ; add 
add ; swp
drp ; dup
add ; swp
drp ; sub
swp ; drp
stw ; nop
jump @gh_find_nextdir
@gh_j21
comp x0002
jpnz @gh_j22
entr @pseudorand     ! ghost in frightened mode => random target
dup ; gtw
entr @score          ! use parity of score as random bit
gtw ; rrw
drp ; rrw
stw ; nop            ! update pseudo random number 
entr @tgx
swp ; stw
swp ; drp
entr @tgy
swp ; stw 
jump @gh_find_nextdir
@gh_j22               ! ghost in eaten mode => target is "home"
entr @tgx
entr x0009
stw ; nop
entr @tgy
entr x0007
stw ; nop


@gh_find_nextdir  ! find next direction for scatter or chase states

!entr x0001
!entr x6666
!stw ; nop

entr @tgx          
dup ; gtw 
rlw ; nop       ! if x_target < 0 (MSB at 1) set it to 0
jpnc @gh_j4
clh ; cll
stw ; nop
jump @gh_j5
@gh_j4
drp ; dup
gtw ; nop
comp x0013     ! if x_target > 19, set it to 19 
jpnc @gh_j5
ldh x00
ldl x13
stw ; nop
@gh_j5
entr @tgy
dup ; gtw 
rlw ; nop      ! same thing for y_target 
jpnc @gh_j6
clh ; cll
stw ; nop
jump @gh_j7
@gh_j6
drp ; dup
gtw ; nop
comp x0013 
jpnc @gh_j7
ldh x00
ldl x13
stw ; nop
@gh_j7
entr @min_dist
entr x0fff       ! actual minimum distance will necessary be lower than that
stw ; nop
entr @jj
entr x0000
stw ; nop
@gh_l2
entr @forbidden_dir   ! reject any U-turn solution
gtw ; nop
entr @jj
gtw ; cmp 
jmpz @gh_j8
entr @xnc        ! test each of the neighboring cells of the ghost
entr @p_xgg  
gtw ; gtw
entr @dvx
entr @jj
gtw ; add
swp ; drp
gtw ; add
swp ; drp
stw ; nop
entr @ync
entr @p_ygg 
gtw ; gtw
entr @dvy
entr @jj
gtw ; add
swp ; drp
gtw ; add
swp ; drp
stw ; nop
entr @xnc
gtw ; nop
entr @ync
gtw ; nop
call @get_cell
comp x0039       ! verify neighboring cell is not wall
jmpc @gh_j8

!entr @ii
!gtw ; nop
!comp x0003
!jpnz @gh_endshowcell
!entr @dc_xy
!entr @xnc
!gtw ; stl
!drp ; nop
!entr @ync
!gtw ; swa
!sth ; nop
!entr @dc_char
!entr x0029
!stw ; nop
!call @disp_ch
!@gh_endshowcell

entr @xnc
gtw ; nop
entr @tgx
gtw ; nop
entr @ync
gtw ; nop
entr @tgy
gtw ; nop
call @calc_sqdist
entr @min_dist
gtw ; cmp
jmpc @gh_j8
drp ; nop        ! min-distance is now target-to-neighboring-cell distance
entr @min_dist
swp ; stw
entr @p_dirg     ! direction will be the one that minimizes the distance
gtw ; nop
entr @jj
gtw ; stw

@gh_j8
entr @jj        ! Test next neighboring cell (other direction)
dup ; gtw
inc ; stw
comp x0004
jpnz @gh_l2

entr @p_dxg    ! update dx_ghost and dy_ghost
gtw ; nop
entr @dvx
entr @p_dirg
gtw ; gtw
add ; gtw
swp ; drp
stw ; nop
entr @p_dyg
gtw ; nop
entr @dvy
entr @p_dirg
gtw ; gtw
add ; gtw
swp ; drp
stw ; nop

@gh_endcell
entr @p_gnocell   ! consider ghost no more on cell to trigger next motion
gtw ; nop
entr x0001
stw ; nop

! end of ghost-on-cell section

@gh_statemach     ! manage ghost state-machine 
entr @p_state     ! (updated after ghost has moved 1 pix)
gtw ; dup
gtw ; nop
comp x0000           ! if ghost in scatter state
jpnz @gh_j9
entr @p_statecnt     ! decrement state counter
gtw ; dup
gtw ; dec 
stw ; nop
comp x0000
jpnz @gh_nextghost
drp ; nop
entr @chased
gtw ; stw 
drp ; drp          ! if counter=0 switch to chase state
drp ; nop
entr x0001
stw ; nop
jump @gh_nextghost 
@gh_j9
comp x0001           ! if ghost in chase state
jpnz @gh_j10
entr @p_statecnt     ! decrement state counter
gtw ; dup
gtw ; dec 
stw ; nop
comp x0000
jpnz @gh_nextghost
drp ; nop
entr @scatterd
gtw ; stw 
drp ; drp          ! if counter=0 switch to chase state
drp ; nop
entr x0000
stw ; nop

@gh_j10
! (space reserved for other states) 
jump @gh_nextghost

@gh_deccount      ! decrement motion counter
entr @p_countg
gtw ; dup
gtw ; dec
stw ; nop

@gh_nextghost
entr @p_state   ! increment pointers for next ghost
dup ; gtw
inc ; stw
entr @p_statecnt
dup ; gtw
inc ; stw
entr @p_xg
dup ; gtw
inc ; stw
entr @p_yg
dup ; gtw
inc ; stw
entr @p_xgg
dup ; gtw
inc ; stw
entr @p_ygg
dup ; gtw
inc ; stw
entr @p_dirg
dup ; gtw
inc ; stw
entr @p_dxg
dup ; gtw
inc ; stw
entr @p_dyg
dup ; gtw
inc ; stw
entr @p_gnocell
dup ; gtw
inc ; stw
entr @p_countg
dup ; gtw
inc ; stw
entr @p_gh_xy
dup ; gtw
inc ; stw

entr @ii
dup ; gtw
inc ; stw
comp x0004         ! 4 for all ghosts
jpnz @gh_mainloop
 
 
! Wait for ~ 1 ms
entr x0001
call @wait

jump @main_loop

@game_over
entr x0400
call @wait
@go_l
call @get_joy   
comp xffff      ! any action on joystick will restart the game
jmpz @go_l
jump @begin

! Routine to wait 
! A = duration of wait (ms)
@wait
entr x07d0
@wloop
dec ; nop
jpnz @wloop
drp ; dec
jpnz @wait
ret ; nop
 
! Routine to get joystick position
@get_joy
clh ; cll
inp ; nop    ! test il=0 = up (N)
jmpc @gj_j1
entr x0000
ret ; nop
@gj_j1
inc ; inp    ! test il=1 = down (S)
jmpc @gj_j2
entr x0002
ret ; nop
@gj_j2
inc ; inp    ! test il=2 = left (W)
jmpc @gj_j3
entr x0003
ret ; nop
@gj_j3
inc ; inp    ! test il=3 = right (E) 
jmpc @gj_j4
entr x0001
ret ; nop
@gj_j4
entr xffff   ! joystick not touched
ret ; nop


! Routine to copy character bitmap into sprite 
! (sprite bitmaps use only high-bytes of words)
! A = target adress, B = source address
@copy_sprite
entr x0004  ! 4 words to be copied
swp ; rd3   ! stack is [S,T,n]
@cs_loop
dup ; ru4
gtw ; sth   ! high-byte char bitmap => high-byte sprite
swp ; inc
swp ; swa
sth ; drp   ! low-byte char bitmap => high-byte sprite
inc ; rd3
inc ; rd3
dec ; ru3
jpnz @cs_loop
ret ; nop


! Routine to get content of a cell of the maze
! in: A = y , B =x
! out: A = char(x,y), B = address of cell
@get_cell
ccf ; rlw  
rlw ; rlw ! y*16
rlw ; nop
swp ; dup
ccf ; rrw ! x/2
rd3 ; add
entr @maze   
add ; rd4 ! addr = @maze + y*16 + x/2
ccf ; rrw ! check parity of x
jmpc @gc_odd
drp ; dup 
gth ; cll 
swa ; ret 
@gc_odd
drp ; dup 
gtl ; clh
ret ; nop


! Routine to calculate square of distance between two cells
! input: A=x1, B=x2, C=y1, D=y2
! output: A=(x2-x1)^2+(y2-y1)^2
@calc_sqdist
cmp ; nop
jpnc @csd_j1
swp ; nop      ! make sure input of square routine is positive integer
@csd_j1
sub ; swp
drp ; ru3      ! same thing for y
cmp ; nop
jpnc @csd_j2
swp ; nop
@csd_j2
sub ; swp
drp ; nop          ! stack is now : A=(y2-y1), B=(x2-x1)
call @calc_square
swp ; nop
call @calc_square
add ; ret


! Routine to calculate square of an integer
! input : A=x, output A=N=x^2
@calc_square
entr x0000
dup ; nop     ! start with i=0, N=0
rd3 ; ccf 
@sq_l1        ! stack is A=x, B=i, C=N
btt ; nop
jpnz @sq_j1
rd3 ; add
ru3 ; nop
@sq_j1
ccf ; rlw 
swp ; inc     ! because of previous left bit-shift, increment the index i twice 
inc ; nop     ! to get the next bit of x
comp x0010
swp ; nop
jpnz @sq_l1
drp ; drp
ret ; nop 
 

! Routine to display score
! (display 16-bit number in decimal without padding 0s)
@disp_score
entr @ds_n
entr @score
gtw ; stw
entr @ds_i
entr x0000
stw ; nop
entr @dc_colors ! will be used to find out if a 0 is padding 
swp ; stw
@ds_l1
entr @dig
entr x0000
stw ; nop
@ds_l2
entr @ds_i
gtw ; nop
entr @pow10
add ; gtw       ! get 10^(4-i)
entr @ds_n
gtw ; cmp       ! N < 10^(4-i) ?
jmpc @ds_j1
sub ; nop
entr @ds_n
swp ; stw       ! N = N-10^(4-i)
entr @dig       ! d = d+1
dup ; gtw
inc ; stw 
jump @ds_l2
@ds_j1
entr @dig
gtw ; nop
comp x0000      ! if d=0, display if i=4 (last digit)
jpnz @ds_prdig
entr @dc_colors
gtw ; nop
comp x0000
jpnz @ds_prdig  ! if d=0 and dc_xy !=0, digit before already printed 
entr @ds_i      ! => display d (0 in middle of number)
gtw ; nop
comp x0004
jmpz @ds_prdig
entr x0020     ! print space if digit cannot be printed
jump @ds_prchar
@ds_prdig      ! print digit
entr @dc_colors
entr x0500
stw ; nop
entr @dig
gtw ; nop
entr x0030 
add ; nop      ! ascii code = 48+d
@ds_prchar
entr @dc_char
swp ; stw 
entr @dc_xy     ! print at x=19+i ; y=0
entr x0013
entr @ds_i
gtw ; add
swp ; drp
stw ; nop
call @disp_ch
@ds_j2
entr @ds_i
dup ; gtw      ! i = i+1
inc ; stw
comp x0005
jpnz @ds_l1
ret ; nop


! Routine to display one character
! (arguments passed into variables)
@disp_ch
! Find starting address in VRAM where character has to be put
entr @dc_xy
gth ; cll
dup ; ccf    ! multiply y by 8*48=384
rrw ; add
entr @dc_xy
gtl ; clh    ! add 2*x
ccf ; rlw
add ; nop
entr @dc_p_vram
swp ; stw
! Find address of character bitmap
entr @dc_char
gtl ; clh
ccf ; rlw    ! multiply by 4 (4 16-bit words per character bitmap)
rlw ; nop 
entr x18ea   ! bitmap of character set starts at x196a (for char=32)
add ; nop     
entr @dc_p_bmp
swp ; stw
! Set counter of pixel lines
entr @dc_c3
entr x0008
stw ; nop
@dc_loop1
! Set counter of pixmap words (for each pixel line)
entr @dc_c2
entr x0002
stw ; nop
! Get bitmap (line of 8 pixels) 
entr @dc_c3
gtw ; rrw 
jmpc @dc_get_l
entr @dc_p_bmp
gtw ; gth
cll; nop
jump @dc_next2
@dc_get_l
entr @dc_p_bmp
gtw ; gtl
swa ; cll
entr @dc_p_bmp ! prepare to read next bitmap line
dup ; gtw
inc ; stw 
drp ; drp ! drop to have bitmap at top of stack
@dc_next2
@dc_loop2
! Reset pixmap
entr x0000
! Get ink and paper as separated words, shift them to the highest nibble
entr @dc_colors
gth ; cll     ! get ink
ccf ; rlw 
rlw ; rlw
rlw ; nop
entr @dc_colors
gtl ; clh     ! get paper 
swa ; ccf 
rlw ; rlw
rlw ; rlw
! Set counter of pixels
entr @dc_c1
entr x0004
stw; drp
drp; nop
! Now stack is [paper,ink,pixmap,bitmap]
! Re-shuffle to [bitmap,pixmap,paper,ink]
rd3 ; rd4
@dc_loop3
! Set pixel value (nibble) in pixmap according to pixel in bitmap
! bitmap is read from left to right (shifting its MSB into CF)
rlw ; nop
jmpc @dc_ink_dot
ru4; orr      ! pixel=paper
ru3; nop 
jump @dc_next1
@dc_ink_dot
rd4 ; rd3
orr ; swp     ! pixel=ink
rd4 ; nop
@dc_next1
! Now stack is [paper,ink,pixmap,bitmap]
! Shift nibbles of ink and paper
ccf ; rrw
rrw ; rrw
rrw ; swp
rrw ; rrw
rrw ; rrw
! Re-shuffle to [bitmap,pixmap,paper,ink]
swp ; rd4
rd4 ; swp 
! Check if pixmap word full
entr @dc_c1    ! decrement c1 counter
dup ; gtw
dec ; stw
drp ; drp  ! drop to restore stack 
jpnz @dc_loop3
! Store pixmap word in video RAM
swp ; nop
entr @dc_p_vram
gtw ; swp
stw ; swp
inc ; nop ! move to next pixmap word on the right
entr @dc_p_vram
swp ; stw
drp ; drp
drp ; nop ! drop to have bitmap at top of stack
! Check if bitmap line fully read
entr @dc_c2
dup ; gtw
dec ; stw
drp ; drp  ! drop to restore stack (and have bitmap at top)
jpnz @dc_loop2
entr @dc_p_vram ! go to next line of image 
dup ; gtw
entr x02E ! = +46 because we already incremented video RAM address twice
add ; swp
drp ; stw
drp ; drp
! Check if character fully displayed
entr @dc_c3
dup ; gtw
dec ; stw
drp ; drp
jpnz @dc_loop1
ret ; nop

! Color LUT

! 0 = black, 1 = dark blue , 2 = yellow , 3 = red, 4 = pink 
! 5 = cyan, 6 = orange, 7 = bright blue, 8 = grey, 9 = white

org x1800
#x0080 ; #x0080 ; #x0080
#x00ff ; #x00ff ; #xffff
#xff00 ; #xff00 ; #x0000
#xff00 ; #x2000 ; #x2000
#xff00 ; #x8000 ; #x8000
#x0000 ; #xff00 ; #xff00
#xff00 ; #x8000 ; #x0000
#x4000 ; #x4000 ; #xff00

! Constant sprite characteristics
org x1826
#x0200     ! Pacman color (yellow)

org x182a
#x0000 ; #x1c00 ; #x3e00 ; #x7f00
#x7f00 ; #x7f00 ; #x3e00 ; #x1c00


! PacMan character set:

! space = space left by pellet
! ! = space left by vitamin
! " = not used
! # = pellet
! $ = vitamin
! % = normal ghost
! & = frightened ghost
! ' = eaten ghost (eyes)
! ( = "ball" pacman
! ) = exploding pacman
! * to . = fruits
! / = space for fruit
! 0 to 9 = 0 to 9
! : = wall N
! ; = wall E
! < = wall S
! = = wall W
! > = wall NE
! ? = wall ES
! @ = wall SW
! A = wall WN
! B = wall NS
! C = wall EW
! D = wall WNE
! E = wall NES
! F = wall ESW
! G = wall SWN
! H = wall NESW
! I = isolated wall
! J = pacman N ph 1
! K = pacman N ph 2
! L = pacman N ph 3
! M = pacman N ph 4
! N = pacman E ph 1
! O = pacman E ph 2
! P = pacman E ph 3
! Q = pacman E ph 4
! R = pacman S ph 1
! S = pacman S ph 2
! T = pacman S ph 3
! U = pacman S ph 4
! V = pacman W ph 1
! W = pacman W ph 2
! X = pacman W ph 3
! Y = pacman W ph 4
! Z = space for fruit

org x186A
@maze

#"?CCCCCCCCFCCCCCCCC@             "
#"B        B        B             "
#"B!;= ;C= : ;C= ;=!B             "
#"B                 B             "
#"B ?@ < ;CFC= < ?@ B             "
#": >A B   :   B >A :             "
#"     E@     ?G                  " 
#"?CC= >A ;C= >A ;CC@             "
#"B                 B             "
#"B ;@ ;C= I ;C= ?= B             " 
#"B! B     /     B !B             "
#"E= : < ;CFC= < : ;G             "
#"B    B   B   B    B             "
#"B ;CCDC= : ;CDCC= B             "
#"B                 B             "
#">CCCCCCCCCCCCCCCCCA             "

@charset
#x0000 ; #x0000 ; #x0000 ; #x0000 
#x0000 ; #x0000 ; #x0000 ; #x0000 
#xffff ; #xffff ; #xffff ; #xffff 
#x0000 ; #x0000 ; #x0800 ; #x0000 
#x0000 ; #x001c ; #x1c1c ; #x0000
@nghbmp
#x1c3e ; #x6b7f ; #x7f7f ; #x7f55
@fghbmp
#x1c3e ; #x6b7f ; #x6b55 ; #x7f55
@eghbmp
#x0000 ; #x7755 ; #x7700 ; #x0000
@bpmbmp
#x001c ; #x3e7f ; #x7f7f ; #x3e1c
@dpmbmp
#x0008 ; #x2a00 ; #x6300 ; #x2a08
#x0070 ; #x0808 ; #x1422 ; #x6363
#x0000 ; #x0000 ; #x0000 ; #x0000
#x0000 ; #x0000 ; #x0000 ; #x0000
#x0000 ; #x0000 ; #x0000 ; #x0000
#x0000 ; #x0000 ; #x0000 ; #x0000
#x0000 ; #x0000 ; #x0000 ; #x0000

! 0 to 9
#x003c ; #x464a ; #x5262 ; #x3c00
#x0018 ; #x2808 ; #x0808 ; #x3e00
#x003c ; #x4202 ; #x3c40 ; #x7e00
#x003c ; #x420c ; #x0242 ; #x3c00
#x0008 ; #x1828 ; #x487e ; #x0800
#x007e ; #x407C ; #x0242 ; #x3c00
#x003c ; #x407c ; #x4242 ; #x3c00
#x007e ; #x0204 ; #x0810 ; #x1000
#x003c ; #x423c ; #x4242 ; #x3c00
#x003c ; #x4242 ; #x3e02 ; #x3c00 

! walls
#x4242 ; #x4242 ; #x4242 ; #x3c00
#x003f ; #x4040 ; #x4040 ; #x3f00
#x003c ; #x4242 ; #x4242 ; #x4242
#x00fc ; #x0202 ; #x0202 ; #xfC00

#x4241 ; #x4040 ; #x4040 ; #x3f00
#x003f ; #x4040 ; #x4040 ; #x4142
#x00fc ; #x0202 ; #x0202 ; #x8242
#x4282 ; #x0202 ; #x0202 ; #xfc00

#x4242 ; #x4242 ; #x4242 ; #x4242
#x00ff ; #x0000 ; #x0000 ; #xff00

#x4281 ; #x0000 ; #x0000 ; #xff00
#x4241 ; #x4040 ; #x4040 ; #x4142
#x00ff ; #x0000 ; #x0000 ; #x8142
#x4282 ; #x0202 ; #x0202 ; #x8242

#x4281 ; #x0000 ; #x0000 ; #x8142
#x003c ; #x4242 ; #x4242 ; #x3c00

! pacman

@pm_phase
#x0000 ; #x0041 ; #x777f ; #x3e1c
#x0000 ; #x2277 ; #x7f7f ; #x3e1c
#x0014 ; #x367f ; #x7f7f ; #x3e1c 
#x0000 ; #x2277 ; #x7f7f ; #x3e1c

#x001c ; #x0e0f ; #x070f ; #x0e1c
#x001c ; #x3e1f ; #x0f1f ; #x3e1c
#x001c ; #x3e7f ; #x1f7f ; #x3e1c 
#x001c ; #x3e1f ; #x0f1f ; #x3e1c

#x001c ; #x3e7f ; #x7741 ; #x0000
#x001c ; #x3e7f ; #x7f77 ; #x2200
#x001c ; #x3e7f ; #x7f7f ; #x3614
#x001c ; #x3e7f ; #x7f77 ; #x2200

#x001c ; #x3878 ; #x7078 ; #x381c
#x001c ; #x3e7c ; #x787c ; #x3e1c
#x001c ; #x3e7f ; #x7c7f ; #x3e1c
#x001c ; #x3e7c ; #x787c ; #x3e1c

! Various constants

! powers of 10 
@pow10
#x2710 ; #x03e8 ; #x0064 ; #x000a ; #x0001

! ghost targets in scatter mode
@tgscx
#x000f ; #x0001 ; #x000f ; #x0001
@tgscy
#x0000 ; #x0000 ; #x000f ; #x000f

! direction vectors
@dvx
#x0000 ; #x0001 ; #x0000 ; #xffff
@dvy
#xffff ; #x0000 ; #x0001 ; #x0000
 

