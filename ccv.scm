(module ccv 
(read-image read-greyscale-image write-image

 dpm-detect-object load-dpm-mixture-model
 sift
 sift-match
 swt-detect-words

 ccv-enable-default-cache ccv-disable-cache ccv-drain-cache

 make-sift
 sift-x sift-y sift-octave sift-level sift-scale sift-angle sift-descriptor
 make-dpm-detection
 dpm-detection-x dpm-detection-y dpm-detection-w 
 dpm-detection-h dpm-detection-confidence
 make-swt-detection
 swt-detection-x swt-detection-y swt-detection-w swt-detection-h

 imlib-image->ccv-image
 imlib-image->ccv-greyscale-image)
(import chicken scheme srfi-1 foreign posix lolevel extras traversal)
(use traversal bind easyffi lolevel matchable define-structure linear-algebra imlib2 gsl)

#>
#include "ccv/lib/ccv.h"
<#

(define ccv-enable-default-cache (foreign-lambda void "ccv_enable_default_cache"))
(define ccv-disable-cache (foreign-lambda void "ccv_disable_cache"))
(define ccv-drain-cache (foreign-lambda void "ccv_drain_cache"))

(define ccv-matrix-free (foreign-lambda void "ccv_matrix_free" (c-pointer "ccv_matrix_t")))

(define (read-image image-filename)
 (set-finalizer!
  ((foreign-lambda* c-pointer
                    ((c-string filename))
                    "ccv_dense_matrix_t *image = 0;
                   ccv_read(filename, &image, CCV_IO_RGB_COLOR | CCV_IO_ANY_FILE);
                   C_return(image);")
   image-filename)
  ccv-matrix-free))

(define (read-greyscale-image image-filename)
 (set-finalizer!
  ((foreign-lambda* c-pointer
                    ((c-string filename))
                    "ccv_dense_matrix_t *image = 0;
                   ccv_read(filename, &image, CCV_IO_GRAY | CCV_IO_ANY_FILE);
                   C_return(image);")
   image-filename)
  ccv-matrix-free))

(define (imlib-image->ccv-image img)
 (set-finalizer!
  ((foreign-lambda* c-pointer
                    (((c-pointer "void*") data) (int width) (int height))
                    "ccv_dense_matrix_t *image = 0;
                      ccv_read(data, &image, CCV_IO_RGB_COLOR | CCV_IO_BGRA_RAW, height, width, 4*width);
                      C_return(image);")
   (image-get-data-for-reading-only img)
   (image-width img)
   (image-height img))
  ccv-matrix-free))

(define (imlib-image->ccv-greyscale-image img)
 (set-finalizer!
  ((foreign-lambda* c-pointer
                    (((c-pointer "void*") data) (int width) (int height))
                    "ccv_dense_matrix_t *image = 0;
                      ccv_read(data, &image, CCV_IO_GRAY | CCV_IO_BGRA_RAW, height, width, 4*width);
                      C_return(image);")
   (image-get-data-for-reading-only img)
   (image-width img)
   (image-height img))
  ccv-matrix-free))

(define (write-image img filename)
 ((foreign-lambda* void
                   (((c-pointer "ccv_dense_matrix_t") img)
                    (c-string filename))
                   "ccv_write(img,filename,NULL, CCV_IO_PNG_FILE, NULL);")
  img filename))

(define (load-dpm-mixture-model filename)
 (set-finalizer!
  ((foreign-lambda c-pointer "ccv_load_dpm_mixture_model" c-string) filename)
  (foreign-lambda void "ccv_dpm_mixture_model_free" c-pointer)))

(define array-get
 (foreign-lambda c-pointer "ccv_array_get" (c-pointer "ccv_array_t") integer))
(define array-free
 (foreign-lambda void "ccv_array_free" c-pointer))

(define ccv-array-t-type
 (foreign-lambda* integer (((c-pointer "ccv_array_t") s))
                  "return(s->type);"))
(define ccv-array-t-sig
 (foreign-lambda* integer64 (((c-pointer  "ccv_array_t") s))
                  "return(s->sig);"))
(define ccv-array-t-refcount
 (foreign-lambda* integer (((c-pointer "ccv_array_t") s))
                  "return(s->refcount);"))
(define ccv-array-t-rnum
 (foreign-lambda* integer (((c-pointer "ccv_array_t") s))
                  "return(s->rnum);"))
(define ccv-array-t-size
 (foreign-lambda* integer (((c-pointer "ccv_array_t") s))
                  "return(s->size);"))
(define ccv-array-t-rsize
 (foreign-lambda* integer (((c-pointer "ccv_array_t") s))
                  "return(s->rsize);"))
(define ccv-array-t-data
 (foreign-lambda* (c-pointer void) (((c-pointer "ccv_array_t") s))
                  "return(s->data);"))
(define ccv-rect-t-x
 (foreign-lambda* integer (((c-pointer "ccv_rect_t") s))
                  "return(s->x);"))
(define ccv-rect-t-y
 (foreign-lambda* integer (((c-pointer "ccv_rect_t") s))
                  "return(s->y);"))
(define ccv-rect-t-width
 (foreign-lambda* integer (((c-pointer "ccv_rect_t") s))
                  "return(s->width);"))
(define ccv-rect-t-height
 (foreign-lambda* integer (((c-pointer "ccv_rect_t") s))
                  "return(s->height);"))
(define ccv-comp-t-rect
 (foreign-lambda* (c-pointer "ccv_rect_t") (((c-pointer "ccv_comp_t") s))
                  "return(&s->rect);"))
(define ccv-comp-t-neighbors
 (foreign-lambda* integer (((c-pointer "ccv_comp_t") s))
                  "return(s->neighbors);"))
(define ccv-comp-t-id
 (foreign-lambda* integer (((c-pointer "ccv_comp_t") s))
                  "return(s->id);"))
(define ccv-comp-t-confidence
 (foreign-lambda* float (((c-pointer "ccv_comp_t") s))
                  "return(s->confidence);"))
(define ccv-root-comp-t-rect
 (foreign-lambda* (c-pointer "ccv_rect_t") (((c-pointer "ccv_root_comp_t") s))
                  "return(&s->rect);"))
(define ccv-root-comp-t-neighbors
 (foreign-lambda* integer (((c-pointer "ccv_root_comp_t") s))
                  "return(s->neighbors);"))
(define ccv-root-comp-t-id
 (foreign-lambda* integer (((c-pointer "ccv_root_comp_t") s))
                  "return(s->id);"))
(define ccv-root-comp-t-confidence
 (foreign-lambda* float (((c-pointer "ccv_root_comp_t") s))
                  "return(s->confidence);"))
(define ccv-root-comp-t-pnum
 (foreign-lambda* integer (((c-pointer "ccv_root_comp_t") s))
                  "return(s->pnum);"))
(define ccv-root-comp-t-part
 (foreign-lambda* (c-pointer "ccv_comp_t") (((c-pointer "ccv_root_comp_t") s))
                  "return(s->part);"))

(define-structure dpm-detection x y w h confidence)

(define (dpm-detect-object image model #!key
                      (threshold 0.6)
                      (interval 8))
 (let ((seq (set-finalizer!
             ((foreign-lambda*
               c-pointer
               ((c-pointer image)
                ((c-pointer "ccv_dpm_mixture_model_t") model)
                (double threshold)
                (integer interval))
               "ccv_dpm_param_t params = ccv_dpm_default_params;
               params.threshold = threshold;
               params.interval = interval;
               C_return(ccv_dpm_detect_objects(image, &model, 1, params));")
              image model threshold interval)
             array-free)))
  (if seq
      (map-n (lambda (i)
              (let* ((result (array-get seq i)) (rect (ccv-root-comp-t-rect result)))
               (make-dpm-detection
                (ccv-rect-t-x rect) (ccv-rect-t-y rect)
                (ccv-rect-t-width rect) (ccv-rect-t-height rect)
                (ccv-root-comp-t-confidence rect))))
       (ccv-array-t-rnum seq))
      '())))

(define-structure sift x y octave level scale angle descriptor)

(define (sift image #!key (noctaves 3) (nlevels 6) (up2x 1)
         (edge-threshold 10) (norm-threshold 0) (peak-threshold 0))
 (let* ((data
         ((foreign-primitive
           scheme-object
           (((c-pointer "ccv_dense_matrix_t") image)
            (integer noctaves) (integer nlevels) (integer up2x)
            (integer edge_threshold) (integer node_threshold)
            (integer peak_threshold)) "
        ccv_sift_param_t params = {
                .noctaves = noctaves,
                .nlevels = nlevels,
                .up2x = up2x,
                .edge_threshold = edge_threshold,
                .norm_threshold = node_threshold,
                .peak_threshold = peak_threshold,
        };
        ccv_array_t* keypoints = 0;
        ccv_dense_matrix_t* desc = 0;
        ccv_sift(image, &keypoints, &desc, 0, params);
        C_word *ptr = C_alloc(C_SIZEOF_LIST(2)+2*C_SIZEOF_POINTER);
        C_return(C_list(&ptr, 2, C_mpointer(&ptr, keypoints),
                                 C_mpointer(&ptr, desc)));")
          image noctaves nlevels up2x edge-threshold norm-threshold peak-threshold))
        (keypoints (set-finalizer! (car data) free))
        (descriptors (set-finalizer! (cadr data) free)))
  (unless (= (ccv-array-t-rnum keypoints) (ccv-array-t-rnum descriptors))
   (error "number of keypoints != number of descriptors"))
  (map-n
    (lambda (k)
     (let* ((keypoint (array-get keypoints k))
            (d ((foreign-lambda*
                 (c-pointer "float")
                 ((integer i)
                  ((c-pointer "ccv_dense_matrix_t") descriptors))
                 "C_return(descriptors->data.f32+i*128);")
                k descriptors)))
      (make-sift
       ((foreign-lambda* float (((c-pointer "ccv_keypoint_t") p)) "C_return(p->x);") keypoint)
       ((foreign-lambda* float (((c-pointer "ccv_keypoint_t") p)) "C_return(p->y);") keypoint)
       ((foreign-lambda* int (((c-pointer "ccv_keypoint_t") p)) "C_return(p->octave);") keypoint)
       ((foreign-lambda* int (((c-pointer "ccv_keypoint_t") p)) "C_return(p->level);") keypoint)
       ((foreign-lambda* double (((c-pointer "ccv_keypoint_t") p)) "C_return(p->regular.scale);") keypoint)
       ((foreign-lambda* double (((c-pointer "ccv_keypoint_t") p)) "C_return(p->regular.angle);") keypoint)
       (->gsl
        (map-n-vector (lambda (i) ((foreign-lambda* float ((integer i) ((c-pointer "float") d))
                                               "C_return(d[i]);") i d))
         128)))))
   (ccv-array-t-rnum keypoints))))

(define (sift-match image-sift object-sift #!key (threshold 0.36))
 (let ((r '()))
  (for-each (lambda (object-keypoint)
             (let* ((o (sift-descriptor object-keypoint))
                    (vl (vector-length o)))
              (let-values
                (((min1 min-keypoint min2)
                  (let loop ((min1 +inf.0) (min-keypoint #f) (min2 +inf.0)
                             (keypoints image-sift))
                   (if (null? keypoints)
                       (values min1 min-keypoint min2)
                       (let* 
                         ((k (sift-descriptor (car keypoints)))
                          (d (let ((n (v- o k))) (dot n n))))
                        (cond ((< d min1) (loop d (car keypoints) min1 (cdr keypoints)))
                              ((< d min2) (loop min1 min-keypoint d (cdr keypoints)))
                              (else (loop min1 min-keypoint min2 (cdr keypoints)))))))))
               (when (< min1 (* min2 threshold))
                (set! r (cons (list object-keypoint min-keypoint) r))))))
   object-sift)
  r))

(define-structure swt-detection x y w h)

(define (swt-detect-words image)
 (let ((words (set-finalizer!
               ((foreign-lambda*
                 (c-pointer "ccv_array_t")
                 (((c-pointer "ccv_dense_matrix_t") image))
                 "C_return(ccv_swt_detect_words(image, ccv_swt_default_params));")
                image)
               array-free)))
  (if words
      (map-n (lambda (i)
              (let ((p (array-get words i)))
               (make-swt-detection
                (ccv-rect-t-x p) (ccv-rect-t-y p)
                (ccv-rect-t-width p) (ccv-rect-t-height p))))
       (ccv-array-t-rnum words))
      '())))
)

