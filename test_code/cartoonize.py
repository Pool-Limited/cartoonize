"""
Internal code snippets were obtained from https://github.com/SystemErrorWang/White-box-Cartoonization/

For it to work tensorflow version 2.x changes were obtained from https://github.com/steubk/White-box-Cartoonization
"""
import os
import uuid
import time
import subprocess

import cv2
import numpy as np
import skvideo.io
try:
    import tensorflow.compat.v1 as tf
except ImportError:
    import tensorflow as tf

import network
import guided_filter

class WB_Cartoonize:
    def __init__(self, weights_dir):
        if not os.path.exists(weights_dir):
            raise FileNotFoundError("Weights Directory not found, check path")
        self.load_model(weights_dir)
        print("Weights successfully loaded")

    def resize_crop(self, image):
        h, w, c = np.shape(image)
        if min(h, w) > 720:
            h, w = (int(720*h/w), 720) if h > w else (720, int(720*w/h))
        image = cv2.resize(image, (w, h),
                            interpolation=cv2.INTER_AREA)
        h, w = (h//8)*8, (w//8)*8
        image = image[:h, :w, :]
        return image

    def load_model(self, weights_dir):
        try:
            tf.disable_eager_execution()
        except:
            None

        tf.reset_default_graph()


        self.input_photo = tf.placeholder(tf.float32, [1, None, None, 3], name='input_image')
        network_out = network.unet_generator(self.input_photo)
        self.final_out = guided_filter.guided_filter(self.input_photo, network_out, r=1, eps=5e-3)

        all_vars = tf.trainable_variables()
        gene_vars = [var for var in all_vars if 'generator' in var.name]
        saver = tf.train.Saver(var_list=gene_vars)

        config = tf.ConfigProto(gpu_options=tf.GPUOptions(allow_growth=True), device_count={'GPU':1})

        self.sess = tf.Session(config=config)

        self.sess.run(tf.global_variables_initializer())
        saver.restore(self.sess, tf.train.latest_checkpoint(weights_dir))

    def infer(self, image):
        image = self.resize_crop(image)
        batch_image = image.astype(np.float32)/127.5 - 1
        batch_image = np.expand_dims(batch_image, axis=0)

        ## Session Run
        output = self.sess.run(self.final_out, feed_dict={self.input_photo: batch_image})

        ## Post Process
        output = (np.squeeze(output)+1)*127.5
        output = np.clip(output, 0, 255).astype(np.uint8)

        return output

    def process_video(self, fname):
        ## Capture video using opencv
        cap = cv2.VideoCapture(fname)

        target_size = (int(cap.get(3)),int(cap.get(4)))
        output_fname = os.path.abspath('{}/{}-{}.mp4'.format(fname.replace(os.path.basename(fname), ''),str(uuid.uuid4())[:7],os.path.basename(fname).split('.')[0]))

        ## Generate the processed frames
        processed_frames = []
        timings = []

        while True:
            ret, frame = cap.read()

            if ret:
                frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

                #st = time.time()
                frame = self.infer(frame)
                #timings.append(time.time()-st)

                frame = cv2.resize(frame, target_size)

                processed_frames.append(frame)

            else:
                break
        cap.release()

        st = time.time()
        skvideo.io.vwrite(output_fname, np.stack(processed_frames), inputdict={'-r':'15/1'}, outputdict={'-r':'15/1'}, verbosity=1)
        sk_vid_time = time.time() - st

        final_name = '{}final_{}'.format(fname.replace(os.path.basename(fname), ''), os.path.basename(output_fname))

        p = subprocess.Popen(['ffmpeg','-i','{}'.format(output_fname), "-pix_fmt", "yuv420p", final_name])
        p.communicate()
        p.wait()

        return final_name

if __name__ == '__main__':
    wbc = WB_Cartoonize(os.path.abspath('./saved_models'))
    cartoon_image = wbc.infer(os.path.abspath('./test.jpg'))
    import matplotlib.pyplot as plt
    plt.imshow(cartoon_image)
    plt.show()
