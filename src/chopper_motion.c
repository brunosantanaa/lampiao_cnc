#include <unistd.h>
#include <stdio.h>

#include "gpio_sys.h"
#include "erl_nif.h"

typedef struct sAxes
  {
    int i;
    int len_axis;
    int len_steps;
    int dir_axis;
    int pin_clk_axis;
    int pin_dir_axis;
    int interval_on;
    int interval_off;
    int * steps;
    struct sAxes * next;
  } Axes;

void create_structure_motion(
  Axes * axis, int * step, 
  int i, int length, int len_axis, 
  int dir, int pin_clk, int pin_dir, int ion, int ioff){
    Axes * p_new;

    p_new = (Axes *) enif_alloc(sizeof(Axes));

    p_new->i = i;
    p_new->len_axis = len_axis;
    p_new->pin_clk_axis = pin_clk;
    p_new->pin_dir_axis = pin_dir;
    p_new->interval_on = ion;
    p_new->interval_off = ioff;
    p_new->dir_axis = dir;
    p_new->len_steps = length;
    p_new->steps = step;

    p_new->next = axis->next;
    axis->next = p_new;
}

int action(Axes * p_root){
  Axes *p;
  Axes *current;

  p = p_root->next;
  current = p;
  
  int n_step;
  int loop = 1;
  
  n_step = p->len_steps;

  int * value;
  int * current_value;

  value = (int *) enif_alloc(p->len_axis*sizeof(int));
  current_value = (int *) enif_alloc(p->len_axis*sizeof(int));

  for(int i = 0; i < p->len_axis; i++) {value[i] = 0;}
  
  for(int i = 0; i < n_step; i++){
    loop = 1;
    p = current;

    while (loop){
      if(!p->i){
        loop = 0;
      }
      if(value[p->i] != p->steps[i]) {
        //step action
        write_gpio(p->pin_dir_axis, p->dir_axis);

        write_gpio(p->pin_clk_axis, HIGH);
        usleep(p->interval_on);
        write_gpio(p->pin_clk_axis, LOW);
        usleep(p->interval_off);
        printf("step axis -> %d; dir -> %d\n", p->i, p->dir_axis);
      }
      value[p->i] = p->steps[i];
      p = p->next;
    }
  }
  return 0;
}

static ERL_NIF_TERM motion_nif(ErlNifEnv * env, int argc, const ERL_NIF_TERM argv []){
  unsigned int len_axis;
  int axis_dir, axis_pin_clk, axis_pin_dir, axis_ion, axis_ioff;
  unsigned int n_steps = 0;

  enif_get_list_length(env, argv[0], &len_axis);
  
  Axes * axes = NULL;
  axes = (Axes *) enif_alloc((sizeof(Axes)));
  
  ERL_NIF_TERM axis     = argv[0];
  ERL_NIF_TERM dir      = argv[1];
  ERL_NIF_TERM pin_clk  = argv[2];
  ERL_NIF_TERM pin_dir  = argv[3];
  ERL_NIF_TERM ion      = argv[4];
  ERL_NIF_TERM ioff     = argv[5];

  ERL_NIF_TERM hd, tl, hd_dir, tl_dir, hd_pin_clk, tl_pin_clk, hd_pin_dir, tl_pin_dir, hd_ion, tl_ion, hd_ioff, tl_ioff;

  enif_get_list_cell(env, argv[0], &hd, &tl);
  enif_get_list_length(env, hd, &n_steps);

  for(unsigned int i = 0; i < len_axis; i++)
  {
    //ERL_NIF_TERM hd, tl;
    enif_get_list_cell(env, axis, &hd, &tl); 
    enif_get_list_cell(env, dir, &hd_dir, &tl_dir); 
    enif_get_list_cell(env, pin_clk, &hd_pin_clk, &tl_pin_clk); 
    enif_get_list_cell(env, pin_dir, &hd_pin_dir, &tl_pin_dir); 
    enif_get_list_cell(env, ion, &hd_ion, &tl_ion); 
    enif_get_list_cell(env, ioff, &hd_ioff, &tl_ioff); 
    int * p_steps;
    p_steps = (int *) enif_alloc(n_steps*sizeof(int));

    ERL_NIF_TERM curr_list_step = hd;
    for(unsigned int j = 0; j < n_steps; j++)
    {
      ERL_NIF_TERM step_hd, step_tl;
      enif_get_list_cell(env, curr_list_step, &step_hd, &step_tl);
      enif_get_int(env, step_hd, &(p_steps[j]));
      
      curr_list_step = step_tl;
    }
    axis = tl;
    dir = tl_dir;
    pin_clk = tl_pin_clk;
    pin_dir = tl_pin_dir;
    ion = tl_ion;
    ioff = tl_ioff;
    
    enif_get_int(env, hd_dir, &axis_dir);
    enif_get_int(env, hd_pin_clk, &axis_pin_clk);
    enif_get_int(env, hd_pin_dir, &axis_pin_dir);
    enif_get_int(env, hd_ion, &axis_ion);
    enif_get_int(env, hd_ioff, &axis_ioff);

    create_structure_motion(
      axes, 
      p_steps, i, n_steps, 
      len_axis, axis_dir, 
      axis_pin_clk, axis_pin_dir, 
      axis_ion, axis_ioff);
  }

  action(axes);

  return enif_make_atom(env, "ok"); 
}


static ERL_NIF_TERM init_motor_nif(ErlNifEnv * env, int argc, const ERL_NIF_TERM argv[]){

  unsigned int n_pins;
  int pin;

  ERL_NIF_TERM hd, tl, list_pin;
  ERL_NIF_TERM error_atom = enif_make_atom(env, "error");
  ERL_NIF_TERM ok_atom = enif_make_atom(env, "ok");

  list_pin = argv[0];

  enif_get_list_length(env, list_pin, &n_pins);
  
  for(unsigned int i = 0; i < n_pins; i++) {
    enif_get_list_cell(env, list_pin, &hd, &tl);
    enif_get_int(env, hd, &pin);
    if(export_gpio(pin) != 0) return enif_make_tuple2(env, error_atom, enif_make_atom(env, "export_pi"));
    if(direction_gpio(pin, OUTPUT) != 0) return enif_make_tuple2(env, error_atom,  enif_make_atom(env, "direction_pin"));
    list_pin = tl;
  }
  
  return ok_atom;
}

static ErlNifFunc nif_funcs[] = 
{
  {"motion", 6, motion_nif, 0},
  {"init_motor", 1, init_motor_nif, 0}
};

ERL_NIF_INIT(Elixir.LamPIaoCNC.ChopperNif, nif_funcs, NULL, NULL, NULL, NULL)
