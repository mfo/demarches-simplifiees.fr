'use client';
import {
  Slider as AriaSlider,
  SliderFill,
  SliderThumb,
  SliderTrack,
  type SliderProps as AriaSliderProps
} from 'react-aria-components';
import './Slider.css';

export type SliderProps = AriaSliderProps<number>;

export function Slider(props: SliderProps) {
  return (
    <AriaSlider {...props}>
      <SliderTrack>
        {/* SliderFill sets an inline height: 100%; drop it so the height from Slider.css applies */}
        <SliderFill
          style={({ defaultStyle }) => ({ ...defaultStyle, height: undefined })}
        />
        <SliderThumb />
      </SliderTrack>
    </AriaSlider>
  );
}
